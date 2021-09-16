require(coda)
require(parallel)
source('/sfs/qumulo/qhome/gxk9jg/scripts/hlmBayes_sp.R')
source('/sfs/qumulo/qhome/gxk9jg/scripts/mcmc_diagnostics.R')
#set.seed(NULL)

Nrep <- c(100,200,500)
nrep <- 10
sim_res <- c()
for(j in 1:3){
  rep_res <- matrix(NA, nc=12, nr=nrep)
  for(i in 1:nrep){
    # Data generating process
    intercept <- 60
    alpha <- -1.5
    delta <- 2.5
    N <- Nrep[j]
    sigma <- 1
    
    coords <- cbind(runif(N,0,10),runif(N,0,10))
    std_coords <- apply(coords,2,function(x){
      (x-mean(x))/sd(x)
    })
    
    xmat <- cbind(1,apply(coords,1, function(x){
      if(x[2]<x[1]) return(0)
      else return(1)
    }))
    
    ir2 <- apply(coords,1, function(x){
      if(x[2]<x[1]) return(0)
      else return(1)
    })
    y <- intercept + alpha*ir2 + delta*(sin(std_coords[,1])+cos(std_coords[,2]))+rnorm(N,0,sigma)
    
    # Ordinary Least squares model
    data_frame <- data.frame(cbind(y,ir2))
    colnames(data_frame) <- c("y","IR")
    model <- lm(y~IR,data=data_frame)
    beta_est <- coef(summary(model))
    
    lw <- spdep::mat2listw(as.matrix(dist(coords)))
    model.stsls <- spatialreg::stsls(y~IR, data=data_frame,lw)
    beta_est_sls <- cbind(coef(summary(model.stsls)),sqrt(diag(model.stsls$var)))
    
    # Spatial Model
    y=y
    X=xmat
    XtX=crossprod(xmat,xmat)
    D = 1:N
    z_init= rep(0,N) # cannot be randomly initialized
    lower_phis=0; upper_phis=30
    shape_sigma=2; scale_sigma=1
    shape_tau=2; scale_tau=0.1 
    mean_beta=rep(0,2)
    prec_beta=1e-3*diag(2)
    Delta=as.matrix(dist(coords))
    steps_init=1
    niter=1e4
    report=1e2
    DtD <- diag(N)
    
    parallel.index <- 1:5; numCores <- detectCores()
    system.time(results <- mclapply(parallel.index, function(x){
      # random starting points
      phis_init = runif(1,lower_phis,upper_phis)
      sigma2_init = 1/rgamma(1,shape=shape_sigma,rate=1/scale_sigma)
      tau2_init = 1/rgamma(1,shape=shape_tau,rate=1/scale_tau)
      beta_init = MASS::mvrnorm(1,mean_beta,prec_beta)
      mc_sp <- hlmBayes_sp(y=y,
                           X=X,
                           XtX=XtX,
                           z_init=z_init,
                           D = D,
                           phis_init=phis_init,
                           lower_phis=lower_phis,
                           upper_phis=upper_phis,
                           sigma2_init=sigma2_init,
                           shape_sigma=shape_sigma,
                           scale_sigma=scale_sigma,
                           tau2_init=tau2_init,
                           shape_tau=shape_tau,
                           scale_tau=scale_tau,
                           beta_init=beta_init,
                           mean_beta=mean_beta,
                           prec_beta=prec_beta,
                           Delta=Delta,
                           steps_init=steps_init,
                           niter=niter,
                           report=report,
                           cov.type = "exponential",
                           spatial.rand.effect = T)
    }, mc.cores = numCores))
    
    post_mcmc <- recover_mcmc(mcmc.obj = results,
                              m.ind=c(0,0,0,1,1),
                              nburn=1000,
                              combine.chains = T)
    
    coef <- rbind(c(median(post_mcmc$post_phis), HPDinterval(post_mcmc$post_phis)),
                  c(median(post_mcmc$post_sigma2), HPDinterval(post_mcmc$post_sigma2)),
                  c(median(post_mcmc$post_tau2), HPDinterval(post_mcmc$post_tau2)),
                  c(median(post_mcmc$post_beta[,1]), HPDinterval(post_mcmc$post_beta[,1])),
                  c(median(post_mcmc$post_beta[,2]), HPDinterval(post_mcmc$post_beta[,2])))
    rownames(coef) <- c("phis","sigma2","tau2","beta0","alpha"); colnames(coef) <- c("median","lower.hpd","upper.hpd")
    beta_est_sp <- c(coef["beta0","median"],coef["alpha","median"])
    y_sp_fitted <- coef["beta0","median"]+coef["alpha","median"]*ir2+apply(post_mcmc$post_z,2,median)
    
    rep_res[i,] <- c(beta_est_sp,
                     beta_est_sls[-1,1],
                     coef(summary(model))[,1],
                     sqrt(mean((y-y_sp_fitted)^2)),
                     sqrt(mean(model.stsls$residuals^2)),
                     sqrt(mean((y-fitted(model))^2)),
                     if(alpha>=coef["alpha","lower.hpd"]& alpha<=coef["alpha","upper.hpd"]) 1 else 0,
                     if(alpha>=beta_est[2,1]-1.96*beta_est[2,2]& alpha<=beta_est[2,1]+1.96*beta_est[2,2]) 1 else 0,
                     if(alpha>=beta_est_sls[3,1]-1.96*beta_est_sls[3,2]& alpha<=beta_est_sls[3,1]+1.96*beta_est_sls[3,2]) 1 else 0)
    cat("N",N,"Iteration",i,"\n")
  }
  agg_res <- t(apply(rep_res[,1:6],1,function(x){
    c(sqrt(mean(x[1]-intercept)^2),
      sqrt(mean(x[2]-alpha)^2),
      sqrt(mean(x[3]-intercept)^2),
      sqrt(mean(x[4]-alpha)^2),
      sqrt(mean(x[5]-intercept)^2),
      sqrt(mean(x[6]-alpha)^2))
  }))
  sim_res <- rbind(sim_res,rbind(c(apply(agg_res,2,mean),apply(rep_res[,7:12],2,mean)),
                                 c(apply(agg_res,2,sd),apply(rep_res[,7:12],2,sd))))
}
sim_res <- round(sim_res,3)
save(sim_res, file="~/data/sim_data_2.RData")

spPlot(length = 11,col_text = "Spectral",data_frame = cbind(coords,fitted(model)),shape = NULL,xlim = c(0,10), ylim=c(0,10))
points(coords[ir2==1,], col="green")
points(coords[ir2==0,], col="blue")
abline(c(0,1), lwd=3,lty="dashed")

spPlot(length = 11,col_text = "Spectral",data_frame = cbind(coords,y_sp_fitted),shape = NULL,xlim = c(0,10), ylim=c(0,10))
points(coords[ir2==1,], col="green")
points(coords[ir2==0,], col="blue")
abline(c(0,1), lwd=3,lty="dashed")

surf <- MBA::mba.surf(cbind(coords,y_sp_fitted),no.X=300,no.Y=300,extend=T,sp=T)$xyz.est
surf1 <- MBA::mba.surf(cbind(coords,fitted(model)),no.X=300,no.Y=300,extend=T,sp=T)$xyz.est
plot3D::persp3D(z=apply(t(matrix(surf1$z,nr=300,nc=300,byrow=T)),2,diff), contour=T, alpha=0.7, phi=40,expand=0.3, image=T)
plot3D::persp3D(z=apply(t(matrix(surf$z,nr=300,nc=300,byrow=T)),2,diff), contour=T, alpha=0.7, phi=40,expand=0.3, image=T)
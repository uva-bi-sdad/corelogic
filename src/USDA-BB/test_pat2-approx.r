Nrep <- c(1e3,5e3,1e4)
nrep <- 10
sim_res <- c()
for(j in 1:3){
  rep_res <- matrix(NA, nc=6, nr=nrep)
  for(i in 1:nrep){
    # Data generating process
    intercept <- 60
    alpha <- -1.5
    delta <- 2.5
    N <- Nrep[j]
    sigma <- 1
    
    coords <- cbind(runif(N,0,1),runif(N,0,1))
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
    y <- rnorm(N,intercept + alpha*ir2 + delta*(sin(std_coords[,1])+cos(std_coords[,2])),sigma)
    
    # NNGP
    data <- data.frame(cbind(coords,y,xmat)); colnames(data) <- c("coords.x","coords.y","y","intercept","ir")
    starting <- list("phi"=6, "sigma.sq"=5, "tau.sq"=3)
    tuning <- list("phi"=1, "sigma.sq"=1, "tau.sq"=1)
    priors <- list("phi.Unif"=c(3/1, 3/0.01), "sigma.sq.IG"=c(2, 1), "tau.sq.IG"=c(2, 0.1))
    cov.model <- "exponential"
    
    model <- spNNGP(y~ir,data=data,coords=coords,
                    n.neighbors = 10,
                    starting=starting,
                    method="latent",
                    tuning=tuning,
                    priors=priors,
                    cov.model = cov.model,
                    n.omp.threads = 4,
                    search.type = "cb",
                    n.samples=5000,
                    verbose = F)
    beta_est_nngp <- apply(model$p.beta.samples[-(1:2500),],2,median)
    y_nngp_fit <- beta_est_nngp[1]+beta_est_nngp[2]*data[,"ir"]
    
    # INLA
    # spatial INLA
    mesh <- inla.mesh.2d(coords, max.edge = c(0.5, 1))
    # plot(mesh);points(coords, col=2)
    proj.obs <- inla.mesh.projector(mesh, loc = coords)
    proj.pred <- inla.mesh.projector(mesh, loc = mesh$loc)
    spde = inla.spde2.pcmatern(mesh = mesh, prior.range = c(0.01, 0.1), prior.sigma = c(10, 0.1)) # Making SPDE
    X <- xmat[,2]
    Amat.obs <- inla.spde.make.A(mesh, loc = coords)
    stack.obs <- inla.stack(data=list(y=y),
                            A=list(Amat.obs, 1),
                            effects=list(c(list(Intercept = 1),
                                           inla.spde.make.index("spatial", spde$n.spde)),
                                         covar=X),
                            tag="obs")
    formula <- y ~ -1 + Intercept + covar + f(spatial, model=spde)
    result1 <- inla(formula,
                    data=inla.stack.data(stack.obs, spde = spde),
                    family="gaussian",
                    control.predictor = list(A = inla.stack.A(stack.obs),
                                             compute = TRUE),
                    verbose = F)
    beta_est_inla <- result1$summary.fixed[,"mode"]
    y_inla_fit <- beta_est_inla[1]+beta_est_inla[2]*data[,"ir"]
    
    rep_res[i,] <- c(beta_est_inla,
                     beta_est_nngp,
                     sqrt(mean((y-y_inla_fit)^2)),
                     sqrt(mean((y-y_nngp_fit)^2)))
    cat("N",N,"Iteration",i,"\n")
  }
  agg_res <- t(apply(rep_res[,1:6],1,function(x){
    c(sqrt(mean(x[1]-intercept)^2),
      sqrt(mean(x[2]-alpha)^2),
      sqrt(mean(x[3]-intercept)^2),
      sqrt(mean(x[4]-alpha)^2))
  }))
  sim_res <- rbind(sim_res,rbind(c(apply(agg_res,2,mean),apply(rep_res[,5:6],2,mean)),
                                 c(apply(agg_res,2,sd),apply(rep_res[,5:6],2,sd))))
}

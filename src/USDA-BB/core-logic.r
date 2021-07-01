require(INLA)
require(sp)
require(geosphere)
find_min_dist <- function(site, sites) {
  min(distHaversine(site, sites,r = 6371)) # in miles
}
source('/sfs/qumulo/qhome/gxk9jg/scripts/spPlot.R')
usa_shape <- raster::getData("GADM",country="USA", level=1)
# Virginia: RD and Wombling ,"OK","MO","LA" ,"Oklahoma","Missouri","Louisiana"
state.symb <- c("NC"); state <- c("North Carolina") #c("Virginia","West Virginia")
load("usda_er_bb_data1.RData")
# use if required
bb_eligibility <- read.csv("broadband_tract_eligibility12-15-20.csv")
load("BIP_New.rds")
load("bip-state.RData")

# proj_crs <- CRS(" +proj=utm +zone=32 +ellps=WGS84 +datum=WGS84 +units=m +no_defs +towgs84=0,0,0")
newbip_all <- sf::st_transform(newbip_union,crs=sf::st_crs(usa_shape))

id.st <- state_data.keep$state%in%state.symb
id.na <- rowSums(is.na(state_data.keep[id.st,c("property_centroid_longitude","property_centroid_latitude")]))==2
id.st <- id.st[!id.na]
# Single state
id.state <- which(unlist(lapply(bbox.bip.names, function(x){
  ifelse(state[1] %in% x,T,F)
})))
# Multiple states
id.state <- intersect(which(unlist(lapply(bbox.bip.names, function(x){
  ifelse(state[1] %in% x,T,F)
}))),which(unlist(lapply(bbox.bip.names, function(x){
  ifelse(state[2] %in% x,T,F)
}))))
# check:: bbox.bip.names[id.state]
options(warn=-1)

for(i in 1:length(id.state)){
  dat <- data.frame(newbip_all$geometry[[1]][[id.state[i]]][[1]])
  points(dat, cex=0.3)
}

# By RUS ID
plot(subset(usa_shape,NAME_1%in%c("North Carolina")))
rus_shape <- subset(newbip_all, ProjectID=="NC1107-B40")
points(rus_shape$geometry[[1]][[1]])

rus_shape <- subset(newbip_all, ProjectID=="NC1107-B40")
dat <- data.frame(rus_shape$geometry[[1]][[1]])
colnames(dat) <- c("long","lat");  coordinates(dat) <- ~long+lat
coords.data <- data.frame(apply(state_data.keep[id.st,c("property_centroid_latitude","property_centroid_longitude")],2,function(x) as.numeric(x)))
coordinates(coords.data) <- ~property_centroid_latitude+property_centroid_longitude
proj4string(dat) <- sp::proj4string(coords.data) <- sp::proj4string(usa_shape)

dat.p <- Polygon(dat)
dat.ps <- Polygons(list(dat.p),1)
dat.sps <- SpatialPolygons(list(dat.ps))
# dat.sps <- spTransform(dat.sps)
# enlarge polygon
# approximately 10 miles out
# use 0.1 for 10 miles out (don't use 20)
dat.sps.enlarged <- rgeos::gBuffer(dat.sps, byid = T,width = 0.1) 

bbox.bip <- bbox(dat.sps.enlarged)
id.near <- apply(coords.data@coords,1,function(x){
  ifelse(x[1]>=bbox.bip["x","min"] & x[1]<=bbox.bip["x","max"] & x[2]>=bbox.bip["y","min"] & x[2]<=bbox.bip["y","max"] ,T,F)
})
sum(id.near)
coords.data.near <- coords.data[id.near,]
proj4string(dat.sps) <- proj4string(coords.data.near)
points.inBIP <- !is.na(over(coords.data.near,dat.sps))
proj4string(dat.sps.enlarged) <- proj4string(coords.data.near)
points.inBIP.en <- !is.na(over(coords.data.near,dat.sps.enlarged))

coords.bip <- coords.data.near[points.inBIP,]
coords.out <- coords.data.near[ifelse(points.inBIP.en-points.inBIP,T,F),]

# Distance to BIP
dist.bip.in <- apply(coords.bip@coords,1,find_min_dist,sites=dat)
#apply(rgeos::gDistance(coords.bip, dat, byid=T),2,min) # within BIP
dist.bip.out <- apply(coords.out@coords,1,find_min_dist,sites=dat)
#apply(rgeos::gDistance(coords.out, dat, byid=T),2,min) # outside BIP

# BIP
id <- as.numeric(rownames(rbind(coords.bip@coords,coords.out@coords)))
# alter master file
# only run the first time: state_data.keep$dist_bip <- NA
# change BIP code :: 
bip_name <- na.omit(unique(state_data.keep[which(id.st)[id],"BIP"]))[1]
state_data.keep[which(id.st)[id],"BIP"] <- c(rep(bip_name,nrow(coords.bip@coords)),rep(paste("n",bip_name,sep=""),nrow(coords.out@coords)))
state_data.keep[which(id.st)[id],"dist_bip"] <- c(dist.bip.in,-dist.bip.out)
# create state data
data.BIP <- state_data.keep[which(id.st)[id],]; dim(data.BIP)
data.BIP$long <- as.numeric(data.BIP$property_centroid_latitude)
data.BIP$lat <- as.numeric(data.BIP$property_centroid_longitude)
#data.BIP$dist_bip <- c(dist.bip.in,-dist.bip.out) # negative since outside boundary
data.BIP$bip <- c(rep(0,nrow(coords.bip@coords)),rep(1,nrow(coords.out@coords)))
shape <- subset(usa_shape, NAME_1%in%state)

pdf(paste("~/RDD-Wombling-",bip_name,".pdf",sep=""))
bfr_id <- sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])<="2010"
aftr_id <- sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])>"2010"
bfr_data <- cbind(data.BIP$long[bfr_id],data.BIP$lat[bfr_id],log(data.BIP$sale_price[bfr_id]))
spPlot(11,"Spectral",data_frame = bfr_data,
       xlim = bbox(dat.sps.enlarged)["x",],ylim = bbox(dat.sps.enlarged)["y",],shape = shape, main="Log-Price (Before 2010)", zlim=c(7,15) )
# plot(shape,xlim=bbox(dat.sps.enlarged)["x",],ylim=bbox(dat.sps.enlarged)["y",])
plot(dat.sps,add=T,lwd=2,border="grey")
plot(dat.sps.enlarged,add=T,lwd=2,border="black")
points(bfr_data[data.BIP$bip[bfr_id]==0, c(1,2)], cex=0.2,col="green")# 
points(bfr_data[data.BIP$bip[bfr_id]==1, c(1,2)], cex=0.2,col="orange") # 

aftr_data <- cbind(data.BIP$long[aftr_id],data.BIP$lat[aftr_id],log(data.BIP$sale_price[aftr_id]))
spPlot(11,"Spectral",data_frame = aftr_data,
       xlim = bbox(dat.sps.enlarged)["x",],ylim = bbox(dat.sps.enlarged)["y",],shape = shape, main="Log-Price (After 2010)", zlim=c(7,15))
# plot(shape,xlim=bbox(dat.sps.enlarged)["x",],ylim=bbox(dat.sps.enlarged)["y",])
plot(dat.sps,add=T,lwd=2,border="grey")
plot(dat.sps.enlarged,add=T,lwd=2,border="black")
points(aftr_data[data.BIP$bip[aftr_id]==0, c(1,2)], cex=0.2,col="green")# 
points(aftr_data[data.BIP$bip[aftr_id]==1, c(1,2)], cex=0.2,col="orange") # 


# before
plot(data.BIP$dist_bip[bfr_id],
     log(data.BIP$sale_price[bfr_id]),
     xlab="Distance from BIP (miles)", ylab="Log(Sale Price)", main="Log-Price vs. Distance to BIP")

abline(h=median(log(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])<="2010" & data.BIP$bip==0])), col="green", lwd=1.5)
abline(h=median(log(na.exclude(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])<="2010" & data.BIP$bip==1]))), col="orange", lwd=1.5)
abline(v=0, col="red",lwd=2.5)
grid()
legend("topright",inset=0.01, legend = c("BIP","Median SP out", "Median SP in"), lwd=c(2,1.5,1.5), col=c("red","orange","green"))

# after
plot(data.BIP$dist_bip[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])>"2010"],
     log(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])>"2010"]),
     xlab="Distance from BIP (miles)", ylab="Log(Sale Price)", main="Log-Price vs. Distance to BIP")

abline(h=median(log(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])>"2010" & data.BIP$bip==0])), col="green", lwd=1.5)
abline(h=median(log(na.exclude(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])>"2010" & data.BIP$bip==1]))), col="orange", lwd=1.5)
abline(v=0, col="red",lwd=2.5)
grid()
legend("topright",inset=0.01, legend = c("BIP","Median SP out", "Median SP in"), lwd=c(2,1.5,1.5), col=c("red","orange","green"))

# difference before
median(log(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])<="2010" & data.BIP$bip==0]))-median(log(na.exclude(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])<="2010" & data.BIP$bip==1])))
# difference after
median(log(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])>"2010" & data.BIP$bip==0]))-median(log(na.exclude(data.BIP$sale_price[sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])>"2010" & data.BIP$bip==1])))

#####################
# Fitting the model #
#####################
# construct X
# data.BIP <- data.BIP[!is.na(data.BIP$bldg_code),]
data.BIP <- data.BIP[!is.na(data.BIP$age),]
data.BIP[is.na(data.BIP$bedrooms),"bedrooms"] <- 0
data.BIP[is.na(data.BIP$sqft_ratio),"sqft_ratio"] <- 1
data.BIP$sale_year <- sapply(as.character(data.BIP$sale_date), function(x) strsplit(x,split="-")[[1]][1])

dif.lprice.rep <- c()
fp_code <- 37
for(i.boot in 1:11){
  if(i.boot==11){
    data.BIP.boot <- data.BIP
    Xmat <- cbind(1,data.BIP.boot$bip,
                  data.BIP.boot$age,
                  data.BIP.boot$nbaths,
                  data.BIP.boot$sqft_ratio,
                  log(data.BIP.boot$acres),
                  log(data.BIP.boot$land_square_footage),
                  data.BIP.boot$bedrooms)
    cnames <- c() 
    levels.x <- names(table(as.character(data.BIP.boot$transaction_type), useNA = "ifany"))
    Xmat <-cbind(Xmat,sapply(levels.x[-1], function(x){
      as.numeric(as.character(data.BIP.boot$transaction_type)==x)
    })) 
    cnames <- c(cnames,paste("transaction_type:",levels.x[-1],sep=""))
    
    levels.x <- as.character(names(table(as.character(data.BIP.boot$bldg_code),useNA = "ifany")))
    Xmat <- cbind(Xmat,sapply(levels.x[!is.na(levels.x)], function(x){
      as.numeric(as.character(data.BIP.boot$bldg_code)==x)
    }))            
    cnames <- c(cnames,paste("bldg_code:",levels.x[!is.na(levels.x)],sep=""))
    
    levels.x <- names(table(as.character(data.BIP.boot$pri_cat_code), useNA = "ifany"))
    Xmat <-cbind(Xmat,sapply(levels.x[-1], function(x){
      as.numeric(as.character(data.BIP.boot$pri_cat_code)==x)
    })) 
    cnames <- c(cnames,paste("pri_cat_code:",levels.x[-1],sep=""))
    
    levels.x <- names(table(as.character(data.BIP.boot$zoning), useNA = "ifany" ))
    Xmat <-cbind(Xmat,sapply(levels.x[-1], function(x){
      as.numeric(as.character(data.BIP.boot$zoning)==x)
    })) 
    cnames <- c(cnames,paste("zoning:",levels.x[-1],sep=""))
    
    #Xmat <- cbind(Xmat,as.numeric(data.BIP.boot$sale_year>2010))
    #cnames <- c(cnames,"after-2010")
    
    geoid.bip <- substr(data.BIP.boot$geoid_blk,1,11)
    geoid.acs <- bb_eligibility$GEOID[bb_eligibility$STATEFP==fp_code]
    id.acs <- match(geoid.bip,geoid.acs)
    acs_data <- list()
    for(i in 1:nrow(data.BIP.boot)){
      if(is.na(data.BIP.boot$sale_year[i])){
        acs_data[[i]] <- as.numeric(bb_eligibility[id.acs[i],c("hs_or_less_2010",
                                                               "renters_2010",
                                                               "poverty_2010",
                                                               "age_65_older_2010",
                                                               "hispanic_2010",
                                                               "black_2010",
                                                               "family_2010",
                                                               "foreign_2010")])
      } else if(data.BIP.boot$sale_year[i]<=2010){
        acs_data[[i]] <- as.numeric(bb_eligibility[id.acs[i],c("hs_or_less_2010",
                                                               "renters_2010",
                                                               "poverty_2010",
                                                               "age_65_older_2010",
                                                               "hispanic_2010",
                                                               "black_2010",
                                                               "family_2010",
                                                               "foreign_2010")])
      }else{
        acs_data[[i]] <- as.numeric(bb_eligibility[id.acs[i],c("hs_or_less_2019",
                                                               "renters_2019",
                                                               "poverty_2019",
                                                               "age_65_older_2019",
                                                               "hispanic_2019",
                                                               "black_2019",
                                                               "family_2019",
                                                               "foreign_2019")])
      }
    }
    acs_data <- do.call(rbind,acs_data)
    colnames(acs_data) <- c("hs_or_less",
                            "renters",
                            "poverty",
                            "age_65_older",
                            "hispanic",
                            "black",
                            "family",
                            "foreign")
    #ftable(data.BIP$bip,as.numeric(data.BIP$sale_year<2010))
    # which interactions to include
    Xmat <- cbind(Xmat,as.numeric(data.BIP$bip)*as.numeric(data.BIP$sale_year>2010))
    cnames <- c(cnames,c("after-2010xbip"))
    colnames(Xmat) <- c("(intercept)","bip","age","nbaths","sqft_ratio","acres","land_square_footage","bedrooms",cnames)
    Xmat <- cbind(Xmat,acs_data)
    coords <- as.matrix(data.BIP.boot[,c("long","lat")])
    rownames(coords) <- NULL
    # Prediction coordinates
    pred.coords1 <- rgeos::gBuffer(dat.sps, byid = T,width = -0.001)
    pred.coords1 <- pred.coords1@polygons[[1]]@Polygons[[1]]@coords
    pred.coords2 <- rgeos::gBuffer(dat.sps, byid = T,width = 0.001) 
    pred.coords2 <- pred.coords2@polygons[[1]]@Polygons[[1]]@coords
    pred.coords <- rbind(pred.coords1,pred.coords2)
    id.match.nn <- apply(as.matrix(dist(pred.coords))[1:nrow(pred.coords1),],1, function(x){
      order(x[-(1:nrow(pred.coords1))])[1]
    })
    pred.coords <- rbind(pred.coords1,pred.coords2[id.match.nn,])
    
    
    mesh <- inla.mesh.2d(coords, max.edge = c(0.5, 1))
    proj.obs <- inla.mesh.projector(mesh, loc=coords)
    proj.pred <- inla.mesh.projector(mesh,loc=pred.coords)
    # Making SPDE: Matern 3/2 :: nu=3/2
    sigma0 = 1
    size = min(c(diff(range(mesh$loc[, 1])), diff(range(mesh$loc[, 2]))))
    range0 = size / 5
    kappa0 = sqrt(8*(3/2)) / range0
    tau0 = 1 / (sqrt(4 * pi) * kappa0 * sigma0)
    spde = inla.spde2.matern(mesh = mesh, alpha=2,
                             B.tau = cbind(log(tau0), -1, +1),
                             B.kappa = cbind(log(kappa0), 0, -1),
                             prior.mean = c(0, 0), prior.prec = c(0.1, 1))
    X <- as.matrix(Xmat[,-1])
    Amat.obs <- inla.spde.make.A(mesh, loc=coords)
    Amat.pred <- inla.spde.make.A(mesh, loc=pred.coords)
    stack.obs <- inla.stack(data=list(y=log(data.BIP.boot$sale_price)),
                            A=list(Amat.obs, 1),
                            effects=list(c(list(Intercept = 1),
                                           inla.spde.make.index("spatial", spde$n.spde)),
                                         covar=X),
                            tag="obs")
    stack.pred <- inla.stack(data=list(y=NA),
                             A=list(Amat.pred,1),
                             effects=list(list(Intercept = 1),
                                          inla.spde.make.index("spatial", 
                                                               nrow(pred.coords))),
                             tag="pred")
    
    stack.f <- inla.stack(stack.obs, stack.pred)
    formula <- y ~ -1 + Intercept + covar + f(spatial, model=spde)
    result1 <- inla(formula,
                    data=inla.stack.data(stack.f, spde = spde),
                    family="gaussian",
                    control.predictor = list(A = inla.stack.A(stack.f),
                                             compute = TRUE),
                    verbose = F,
                    control.compute = list(config=T))
    # summary(result1)
    coef <- result1$summary.fixed[,-7]
    rownames(coef) <- colnames(Xmat) ; round(coef,4)
    save(coef, file=paste("coef-",bip_name,".RData"))
    #save(coef,file = paste("/sfs/qumulo/qhome/gxk9jg/coef-bip-",bip_name,"-acs.RData",sep=""))
    index <- inla.stack.index(stack = stack.f, tag = "pred")$data
    pred_mean <- result1$summary.fitted.values[index, "mean"]
    dif.lprice <- (pred_mean[-(1:nrow(pred.coords1))]+coef["bip","mode"])-pred_mean[1:nrow(pred.coords1)]
  }else{
    id.boot <- list(out.bip=sample(1:nrow(data.BIP[data.BIP$bip==1,]),size = round(0.99*nrow(data.BIP[data.BIP$bip==1,]))),
                    in.bip=sample(1:nrow(data.BIP[data.BIP$bip==0,]),size = round(0.99*nrow(data.BIP[data.BIP$bip==0,]))))
    
    data.BIP.boot <- rbind(data.BIP[data.BIP$bip==1,][id.boot$out.bip,],
                           data.BIP[data.BIP$bip==0,][id.boot$in.bip,])
    Xmat <- cbind(1,data.BIP.boot$bip,
                  data.BIP.boot$age,
                  data.BIP.boot$nbaths,
                  data.BIP.boot$sqft_ratio,
                  log(data.BIP.boot$acres),
                  log(data.BIP.boot$land_square_footage),
                  data.BIP.boot$bedrooms)
    cnames <- c() 
    levels.x <- names(table(as.character(data.BIP.boot$transaction_type), useNA = "ifany"))
    Xmat <-cbind(Xmat,sapply(levels.x[-1], function(x){
      as.numeric(as.character(data.BIP.boot$transaction_type)==x)
    })) 
    cnames <- c(cnames,paste("transaction_type:",levels.x[-1],sep=""))
    
    levels.x <- as.character(names(table(as.character(data.BIP.boot$bldg_code),useNA = "ifany")))
    Xmat <- cbind(Xmat,sapply(levels.x[!is.na(levels.x)], function(x){
      as.numeric(as.character(data.BIP.boot$bldg_code)==x)
    }))            
    cnames <- c(cnames,paste("bldg_code:",levels.x[!is.na(levels.x)],sep=""))
    
    levels.x <- names(table(as.character(data.BIP.boot$pri_cat_code), useNA = "ifany"))
    Xmat <-cbind(Xmat,sapply(levels.x[-1], function(x){
      as.numeric(as.character(data.BIP.boot$pri_cat_code)==x)
    })) 
    cnames <- c(cnames,paste("pri_cat_code:",levels.x[-1],sep=""))
    
    levels.x <- names(table(as.character(data.BIP.boot$zoning), useNA = "ifany" ))
    Xmat <-cbind(Xmat,sapply(levels.x[-1], function(x){
      as.numeric(as.character(data.BIP.boot$zoning)==x)
    })) 
    cnames <- c(cnames,paste("zoning:",levels.x[-1],sep=""))
    
    Xmat <- cbind(Xmat,as.numeric(data.BIP.boot$sale_year>2010))
    cnames <- c(cnames,"after-2010")
    
    geoid.bip <- substr(data.BIP.boot$geoid_blk,1,11)
    geoid.acs <- bb_eligibility$GEOID[bb_eligibility$STATEFP==fp_code]
    id.acs <- match(geoid.bip,geoid.acs)
    acs_data <- list()
    for(i in 1:nrow(data.BIP.boot)){
      if(is.na(data.BIP.boot$sale_year[i])){
        acs_data[[i]] <- as.numeric(bb_eligibility[id.acs[i],c("hs_or_less_2010",
                                                               "renters_2010",
                                                               "poverty_2010",
                                                               "age_65_older_2010",
                                                               "hispanic_2010",
                                                               "black_2010",
                                                               "family_2010",
                                                               "foreign_2010")])
      }else if(data.BIP.boot$sale_year[i]<=2010){
        acs_data[[i]] <- as.numeric(bb_eligibility[id.acs[i],c("hs_or_less_2010",
                                                               "renters_2010",
                                                               "poverty_2010",
                                                               "age_65_older_2010",
                                                               "hispanic_2010",
                                                               "black_2010",
                                                               "family_2010",
                                                               "foreign_2010")])
      }else{
        acs_data[[i]] <- as.numeric(bb_eligibility[id.acs[i],c("hs_or_less_2019",
                                                               "renters_2019",
                                                               "poverty_2019",
                                                               "age_65_older_2019",
                                                               "hispanic_2019",
                                                               "black_2019",
                                                               "family_2019",
                                                               "foreign_2019")])
      }
    }
    acs_data <- do.call(rbind,acs_data)
    colnames(acs_data) <- c("hs_or_less",
                            "renters",
                            "poverty",
                            "age_65_older",
                            "hispanic",
                            "black",
                            "family",
                            "foreign")
    #ftable(data.BIP$bip,as.numeric(data.BIP$sale_year<2010))
    # which interactions to include
    Xmat <- cbind(Xmat,as.numeric(data.BIP$bip)*as.numeric(data.BIP$sale_year>2010))
    cnames <- c(cnames,c("after-2010xbip"))
    colnames(Xmat) <- c("(intercept)","bip","age","nbaths","sqft_ratio","acres","land_square_footage","bedrooms",cnames)
    Xmat <- cbind(Xmat,acs_data)
    coords <- as.matrix(data.BIP.boot[,c("long","lat")])
    rownames(coords) <- NULL
    # Prediction coordinates
    pred.coords1 <- rgeos::gBuffer(dat.sps, byid = T,width = -0.001)
    pred.coords1 <- pred.coords1@polygons[[1]]@Polygons[[1]]@coords
    pred.coords2 <- rgeos::gBuffer(dat.sps, byid = T,width = 0.001) 
    pred.coords2 <- pred.coords2@polygons[[1]]@Polygons[[1]]@coords
    pred.coords <- rbind(pred.coords1,pred.coords2)
    id.match.nn <- apply(as.matrix(dist(pred.coords))[1:nrow(pred.coords1),],1, function(x){
      order(x[-(1:nrow(pred.coords1))])[1]
    })
    pred.coords <- rbind(pred.coords1,pred.coords2[id.match.nn,])
    
    
    mesh <- inla.mesh.2d(coords, max.edge = c(0.5, 1))
    proj.obs <- inla.mesh.projector(mesh, loc=coords)
    proj.pred <- inla.mesh.projector(mesh,loc=pred.coords)
    # Making SPDE: Matern 3/2 :: nu=3/2
    sigma0 = 1
    size = min(c(diff(range(mesh$loc[, 1])), diff(range(mesh$loc[, 2]))))
    range0 = size / 5
    kappa0 = sqrt(8*(3/2)) / range0
    tau0 = 1 / (sqrt(4 * pi) * kappa0 * sigma0)
    spde = inla.spde2.matern(mesh = mesh, alpha=2,
                             B.tau = cbind(log(tau0), -1, +1),
                             B.kappa = cbind(log(kappa0), 0, -1),
                             prior.mean = c(0, 0), prior.prec = c(0.1, 1))
    X <- as.matrix(Xmat[,-1])
    Amat.obs <- inla.spde.make.A(mesh, loc=coords)
    Amat.pred <- inla.spde.make.A(mesh, loc=pred.coords)
    stack.obs <- inla.stack(data=list(y=log(data.BIP.boot$sale_price)),
                            A=list(Amat.obs, 1),
                            effects=list(c(list(Intercept = 1),
                                           inla.spde.make.index("spatial", spde$n.spde)),
                                         covar=X),
                            tag="obs")
    stack.pred <- inla.stack(data=list(y=NA),
                             A=list(Amat.pred,1),
                             effects=list(list(Intercept = 1),
                                          inla.spde.make.index("spatial", 
                                                               nrow(pred.coords))),
                             tag="pred")
    
    stack.f <- inla.stack(stack.obs, stack.pred)
    formula <- y ~ -1 + Intercept + covar + f(spatial, model=spde)
    result1 <- inla(formula,
                    data=inla.stack.data(stack.f, spde = spde),
                    family="gaussian",
                    control.predictor = list(A = inla.stack.A(stack.f),
                                             compute = TRUE),
                    verbose = F,
                    control.compute = list(config=T))
    # summary(result1)
    coef <- result1$summary.fixed[,-7]
    rownames(coef) <- colnames(Xmat) ; round(coef,4)
    index <- inla.stack.index(stack = stack.f, tag = "pred")$data
    pred_mean <- result1$summary.fitted.values[index, "mean"]
    dif.lprice <- (pred_mean[-(1:nrow(pred.coords1))]+coef["bip","mode"])-pred_mean[1:nrow(pred.coords1)]
  }
  dif.lprice.rep <- cbind(dif.lprice.rep,dif.lprice)
  cat("Iteration",i.boot,"\n")
}
#save(coef, file=paste("coef-",bip_name,".RData",sep=""))
#bname <- c("CA1113","GA1105","IN1104","NC1107")
#did_estimate <- c()
#for(i in 1:length(bname)){
#  load(paste("coef-",bname[i],".RData",sep=""))
#  did_estimate <- rbind(did_estimate,coef["after-2010xbip",])
#}
#rownames(did_estimate) <- c("CA1113-A40","GA1105-A40","IN1104-A40","NC1107-B40")
#save(did_estimate,file="dis-estimate.RData")

dif.lprice.rep.out <- cbind.data.frame(t(apply(dif.lprice.rep[,1:10],1,quantile, probs=c(0.025,0.975))),
                                       apply(t(apply(dif.lprice.rep[,1:10],1,quantile, probs=c(0.025,0.975))),1,sd),
                                       apply(t(apply(dif.lprice.rep[,1:10],1,quantile, probs=c(0.025,0.975))),1,function(x) ifelse((x[1]<0 &x[2]<0) | (x[1]>0 &x[2]>0),1,0)))
colnames(dif.lprice.rep.out) <- c("l","u","sd","sig")
dif.lprice <- dif.lprice.rep[,11]
class_id <- classInt::classIntervals(dif.lprice,30)
id.col <- sapply(dif.lprice, function(x){
  counter <- 0
  for(i in 2:length(class_id$brks)) counter <- counter+ifelse(x <= class_id$brks[i] & x >= class_id$brks[i-1],i-1,0)
  counter
})
colvec <- colorRampPalette(RColorBrewer::brewer.pal(11,"Spectral"))(30)
colvec <- colvec[id.col]
mat <- matrix(c(2,1), nr=1,nc=2, byrow=T)
layout(mat,
       widths = c(5,1.5))

legend_image <- as.raster(matrix(colorRampPalette(RColorBrewer::brewer.pal(11,"Spectral"))(30), ncol=1))
plot(c(0,3),c(0,1),type = 'n', axes = F,xlab = '', ylab = '', main = '')
text(x=2, y = seq(0.01,0.99,l=6), labels = round(seq(range(dif.lprice)[1],range(dif.lprice)[2],l=6),2))
rasterImage(legend_image, 0, 0, 1,1)

plot(pred.coords2[id.match.nn,], xlim = bbox(dat.sps.enlarged)["x",],ylim = bbox(dat.sps.enlarged)["y",],
     xlab="Longitude",ylab="Latitude", main="Regression Discontinuity Design",cex=0.5)
# plot(dat.sps,add=T,lwd=7,border="grey")
for(i in 1:(nrow(pred.coords1)-1)){
  if(dif.lprice.rep.out$sig[i]==1){
    lines(pred.coords1[i:(i+1),], col=colvec[i],lwd=7)
    #points(grid.points[i:(i+1),], col="black", pch=16)
  }
  else lines(pred.coords1[i:(i+1),], col=colvec[i],lwd=2)
  #lines(pred.coords1[i:(i+1),], col=colvec[i],lwd=dif.lprice.rep.out$sd[i]*10)
  #if(dif.lprice.rep.out$sig[i]==1) lines(pred.coords1[i:(i+1),], col="black",lwd=1)
} 
points(coords.bip@coords, col="green", cex=0.2)
points(coords.out@coords, col="orange", cex=0.2)
plot(dat.sps.enlarged,add=T,lwd=1,border="grey")
plot(shape, add=T, border="darkred")

# Wombling
# Extract posterior samples
post_sample <- inla.posterior.sample(n=100, result1)
post_hyper <- do.call(rbind,lapply(post_sample, function(x){
  c(1/x$hyperpar[1],exp(x$hyperpar[3]))
}))
colnames(post_hyper) <- c("sigma2","phi")

tag <- sapply(rownames(post_sample[[1]]$latent),function(x) strsplit(x,":")[[1]][1])
post_latent <- do.call(rbind,lapply(post_sample, function(x) x$latent[which(tag=="spatial"),]))
colnames(post_latent) <- result1$summary.random$spatial$ID

grid.points <- dat.sps@polygons[[1]]@Polygons[[1]]@coords
Delta <- as.matrix(dist(mesh$loc[,c(1,2)]))

# Matern1 Gradient
samples <- 1:100
numCores <- detectCores();parallel.index <- 1:10
samp.list <- split(samples, ceiling(seq_along(samples)/(length(samples)/10)))


#Sig.Z.grad.est <- Matrix(median(post_hyper[,"sigma2"])*(1+median(post_hyper[,"phi"])*Delta)*exp(-median(post_hyper[,"phi"])*Delta)+1e-10*diag(nrow(Delta)))
#system.time(s.grad.in <- chol2inv(chol(Sig.Z.grad.est)))

# Matern1 Gradient
system.time(results.grad <- mclapply(parallel.index, function(x){
  samp.x <- samp.list[[x]]
  post_phi_thin <- post_hyper[samp.x,"phi"]
  post_sigma2_thin <- post_hyper[samp.x,"sigma2"]
  post_z_thin <- post_latent[samp.x,]
  
  mcmc.grad <- list()
  for(i.mcmc in 1:length(samp.x)){
    
    phi.grad.est <- post_phi_thin[i.mcmc]
    sig2.grad.est <- post_sigma2_thin[i.mcmc]
    z.grad.est <- post_z_thin[i.mcmc,]
    
    grad.est <- matrix(NA, nr=nrow(grid.points),nc=2)
    Sig.Z.grad.est <- median(post_hyper[,"sigma2"])*(1+median(post_hyper[,"phi"])*Delta)*exp(-median(post_hyper[,"phi"])*Delta)+1e-10*diag(nrow(Delta))
    s.grad.in <- chol2inv(chol(Sig.Z.grad.est))
    for(i in 1:nrow(grid.points)){
      s0 <- grid.points[i,]
      dist.s0 <- apply(mesh$loc[,c(1,2)],1,function(x) sqrt(sum((x-s0)^2)) )
      delta.s0 <- t(apply(mesh$loc[,c(1,2)],1,function(x) x-s0 ))
      
      # matern1 covariance
      nabla.K <- -sig2.grad.est*phi.grad.est^2*exp(-phi.grad.est*dist.s0)*delta.s0
      V.0 <- phi.grad.est^2*sig2.grad.est*diag(2)
      nabla.K.t <- -t(nabla.K)
      tmp <- crossprod(t(nabla.K.t),s.grad.in)
      mean.grad <- crossprod(t(tmp),
                             z.grad.est)
      var.grad <- V.0-crossprod(t(tmp),nabla.K)
      
      grad.est[i,] <- as.vector(MASS::mvrnorm(1,mean.grad,var.grad))
      cat("Points Done",i,"\n")
    }
    mcmc.grad[[i.mcmc]] <- grad.est
    cat("Iteration",i.mcmc,"\n")
  }
  return(mcmc.grad)
  }, mc.cores = 20))

# calculate normal direction along BIP
# choose normal such that greater than 0 corresponds to 
# direction inside to outside
# results.grad <- results.grad[-10]
norm_dir <- matrix(NA, nc=3,nr=nrow(grid.points)-1)
for(i in 1:(nrow(grid.points)-1)){
  tmp.n <- grid.points[(i+1),]-grid.points[i,]
  tmp.n <- rev(tmp.n/sqrt(sum(tmp.n^2)))
  tmp.n[1] <- -tmp.n[1]
  # compute line-segement length
  norm_dir[i,] <- c(tmp.n,dist(grid.points[c(i:(i+1)),]))
}


grad.bip <- lapply(results.grad, function(x){
  lapply(x, function(y){
    proj.grad <- rep(NA,nrow(grid.points)-1)
    for(i in 1:(nrow(grid.points)-1)){
      proj.grad[i] <- y[i,]%*%matrix(norm_dir[i,c(1,2)],nc=1)*norm_dir[i,3] # weight by line-segment length
    }
    proj.grad
  })
})

grad.bip <- lapply(grad.bip, function(x){
  do.call(rbind,x)
})

grad.bip <- do.call(rbind, lapply(grad.bip, function(x) apply(x,2,median)))
grad.bip <- coda::as.mcmc(grad.bip)
grad.est <- cbind.data.frame(grid.points[-nrow(grid.points),],median=apply(grad.bip,2,median),sd=apply(grad.bip,2,sd), coda::HPDinterval(grad.bip)); rownames(grad.est) <- NULL
grad.est$sig <- apply(grad.est,1, function(x) ifelse((x[4]>0 & x[5]>0) |(x[4]<0 & x[5]<0),1,0))
sum(grad.est[,"median"])/sum(norm_dir[,3]); mean(abs(dif.lprice))

# color coding gardients
class_id <- classInt::classIntervals(grad.est[,"median"],30)
id.col <- sapply(grad.est[,"median"], function(x){
  counter <- 0
  for(i in 2:length(class_id$brks)) counter <- ifelse(x <= class_id$brks[i] & x >= class_id$brks[i-1],i-1,counter)
  counter
})
colvec <- colorRampPalette(RColorBrewer::brewer.pal(11,"Spectral"))(30)
colvec <- colvec[id.col]
mat <- matrix(c(2,1), nr=1,nc=2, byrow=T)
layout(mat,
       widths = c(5,1.5))

legend_image <- as.raster(matrix(colorRampPalette(RColorBrewer::brewer.pal(11,"Spectral"))(30), ncol=1))
plot(c(0,3),c(0,1),type = 'n', axes = F,xlab = '', ylab = '', main = '')
text(x=2, y = seq(0.01,0.99,l=6), labels = round(seq(range(grad.est$median)[1],range(grad.est$median)[2],l=6),2))
rasterImage(legend_image, 0, 0, 1,1)

plot(pred.coords2[id.match.nn,], xlim = bbox(dat.sps.enlarged)["x",],ylim = bbox(dat.sps.enlarged)["y",],
     xlab="Longitude",ylab="Latitude", main="Wombling",cex=0.5)
#plot(dat.sps,add=T,lwd=7,border="grey")
for(i in 1:(nrow(grid.points)-1)){
  if(grad.est$sig[i]==1){
    lines(grid.points[i:(i+1),], col=colvec[i],lwd=7)
    #points(grid.points[i:(i+1),], col="black", pch=16)
  }
  else lines(grid.points[i:(i+1),], col=colvec[i],lwd=2)
} 
points(coords.bip@coords, col="green", cex=0.2)
points(coords.out@coords, col="orange", cex=0.2)
plot(dat.sps.enlarged,add=T,lwd=1,border="grey")
plot(shape, add=T, border="darkred")

dif.lprice.sd1.out <- cbind.data.frame(dif.lprice.rep[,11]-1.96*coef["bip","sd"],
                                       dif.lprice.rep[,11]+1.96*coef["bip","sd"],
                                       apply(cbind(dif.lprice.rep[,11]-1.96*coef["bip","sd"],
                                                   dif.lprice.rep[,11]+1.96*coef["bip","sd"]),1,function(x) ifelse((x[1]<0 &x[2]<0) | (x[1]>0 &x[2]>0),1,0)))
colnames(dif.lprice.sd1.out) <- c("l","u","sig")
dif.lprice <- dif.lprice.rep[,11]
class_id <- classInt::classIntervals(dif.lprice,30)
id.col <- sapply(dif.lprice, function(x){
  counter <- 0
  for(i in 2:length(class_id$brks)) counter <- counter+ifelse(x <= class_id$brks[i] & x >= class_id$brks[i-1],i-1,0)
  counter
})
colvec <- colorRampPalette(RColorBrewer::brewer.pal(11,"Spectral"))(30)
colvec <- colvec[id.col]
mat <- matrix(c(2,1), nr=1,nc=2, byrow=T)
layout(mat,
       widths = c(5,1.5))

legend_image <- as.raster(matrix(colorRampPalette(RColorBrewer::brewer.pal(11,"Spectral"))(30), ncol=1))
plot(c(0,3),c(0,1),type = 'n', axes = F,xlab = '', ylab = '', main = '')
text(x=2, y = seq(0.01,0.99,l=6), labels = round(seq(range(dif.lprice)[1],range(dif.lprice)[2],l=6),2))
rasterImage(legend_image, 0, 0, 1,1)

plot(pred.coords2[id.match.nn,], xlim = bbox(dat.sps.enlarged)["x",],ylim = bbox(dat.sps.enlarged)["y",],
     xlab="Longitude",ylab="Latitude", main="Regression Discontinuity Design")
# plot(dat.sps,add=T,lwd=7,border="grey")
for(i in 1:(nrow(pred.coords1)-1)){
  if(dif.lprice.sd1.out$sig[i]==1) lines(pred.coords1[i:(i+1),], col=colvec[i],lwd=7)
  else lines(pred.coords1[i:(i+1),], col=colvec[i],lwd=2)
} 
points(coords.bip@coords, col="green", cex=0.2)
points(coords.out@coords, col="orange", cex=0.2)
plot(dat.sps.enlarged,add=T,lwd=1,border="grey")
plot(shape, add=T, border="darkred")




par(mfcol=c(1,1))
hist(grad.est[,"median"], main="Distribution of Gradients")
hist(dif.lprice, main="Regression discontinuities")
dev.off()

# finally save master file
save(state_data.keep, file="usda_er_bb_data1.RData")

load(paste("/sfs/qumulo/qhome/gxk9jg/coef-bip-","WV1103","-acs.RData",sep=""))
xtable::xtable(round(coef,4),auto=T)

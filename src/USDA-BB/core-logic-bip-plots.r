load("usda_er_bb_data1.RData")
load("BIP_New.rds")
load("bip-state.RData")

usa_shape <- raster::getData("GADM",country="USA", level=1)

bip.names <- read.csv("bip-awardee.csv")[1:297,]
state.list <- read.csv("state-list.csv"); state.list <- rbind(state.list,c("District of Columbia","DC"))

nsales <- rep(NA,nrow(bip.names))
for(i in 260:nrow(bip.names)){
  if(bip.names[i,1] %in% newbip_all$ProjectID){
    state.symb <- substr(bip.names[i,1],start = 1,stop = 2)
    state <- state.list[which(state.list$State.1==state.symb),1]
    
    id.st <- state_data.keep$state%in%state.symb
    id.na <- rowSums(is.na(state_data.keep[id.st,c("property_centroid_longitude","property_centroid_latitude")]))==2
    id.st <- id.st[!id.na]
    
    rus_shape <- subset(newbip_all, ProjectID==bip.names[i,1])
    if("matrix" %in% class(rus_shape$geometry[[1]][[1]])){
      dat <- data.frame(rus_shape$geometry[[1]][[1]]) 
    }else{
      dat <- data.frame(rus_shape$geometry[[1]][[1]][[1]]) 
    }
    #data.frame(newbip_all$geometry[[1]][[id.state[1]]][[1]])
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
    dat.sps.enlarged <- rgeos::gBuffer(dat.sps, byid = T,width = 0.1) 
    
    bbox.bip <- bbox(dat.sps.enlarged)
    id.near <- apply(coords.data@coords,1,function(x){
      ifelse(x[1]>=bbox.bip["x","min"] & x[1]<=bbox.bip["x","max"] & x[2]>=bbox.bip["y","min"] & x[2]<=bbox.bip["y","max"] ,T,F)
    })
    if(sum(id.near)>10){
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
      bip_name <- bip.names[i,1]
      #na.omit(unique(state_data.keep[which(id.st)[id],"BIP"]))[1]
      state_data.keep[which(id.st)[id],"BIP"] <- c(rep(bip_name,nrow(coords.bip@coords)),rep(paste("n",bip_name,sep=""),nrow(coords.out@coords)))
      state_data.keep[which(id.st)[id],"dist_bip"] <- c(dist.bip.in,-dist.bip.out)
      # create state data
      data.BIP <- state_data.keep[which(id.st)[id],]
      nsales[i] <- nrow(data.BIP)
      data.BIP$long <- as.numeric(data.BIP$property_centroid_latitude)
      data.BIP$lat <- as.numeric(data.BIP$property_centroid_longitude)
      #data.BIP$dist_bip <- c(dist.bip.in,-dist.bip.out) # negative since outside boundary
      data.BIP$bip <- c(rep(0,nrow(coords.bip@coords)),rep(1,nrow(coords.out@coords)))
      shape <- subset(usa_shape, NAME_1%in%state)
      
      #if(state.symb!="DC"){
        pdf(paste("~/RDD-Wombling-",bip_name,".pdf",sep=""))
        bfr_id <- sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])<="2010"
        aftr_id <- sapply(data.BIP$sale_date, function(x) strsplit(as.character(x),split="-")[[1]][1])>"2010"
        spPlot(11,"Spectral",data_frame = cbind(data.BIP$long,data.BIP$lat,log(data.BIP$sale_price)),
               xlim = bbox(dat.sps.enlarged)["x",],ylim = bbox(dat.sps.enlarged)["y",],shape = shape, main="Log-Price")
        # plot(shape,xlim=bbox(dat.sps.enlarged)["x",],ylim=bbox(dat.sps.enlarged)["y",])
        plot(dat.sps,add=T,lwd=2,border="grey")
        plot(dat.sps.enlarged,add=T,lwd=2,border="black")
        points(coords.bip, cex=0.2,col="green")# 
        points(coords.out, cex=0.2,col="orange") # 
        
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
        dev.off() 
      #}
    }else{
      nsales[i] <- 0
    }
  }
  cat("# of RUS:","\t",i,"\n")
}
bip.names$nsales <- nsales
write.csv(bip.names, file="bip-awardee.csv")

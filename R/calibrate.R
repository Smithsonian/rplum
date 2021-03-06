### this is a copy of an .R file of the 'rbacon' package by the same authors as those of 'rplum'. Both packages are distributed under the GPL (>= 2) license


#' @name copyCalibrationCurve
#' @title Copy a calibration curve.
#' @description Copy one of the the calibration curves into memory.
#' @details Copy the radiocarbon calibration curve defined by cc into memory.
#' @return The calibration curve (invisible).
#' @param cc Calibration curve for 14C dates: \code{cc=1} for IntCal20 (northern hemisphere terrestrial), \code{cc=2} for Marine20 (marine),
#' \code{cc=3} for SHCal20 (southern hemisphere terrestrial).
#' @param postbomb Use \code{postbomb=TRUE} to get a postbomb calibration curve (default \code{postbbomb=FALSE}).
#' @author Maarten Blaauw, J. Andres Christen
#' @seealso \url{http://www.qub.ac.uk/chrono/blaauw/manualBacon_2.3.pdf}
#' @export
copyCalibrationCurve <- function(cc=1, postbomb=FALSE) {
  if(postbomb) {
    if(cc==1) fl <- "postbomb_NH1.14C" else
      if(cc==2) fl <- "postbomb_NH2.14C" else
        if(cc==3) fl <- "postbomb_NH3.14C" else
          if(cc==4) fl <- "postbomb_SH1-2.14C" else
            if(cc==5) fl <- "postbomb_SH3.14C" else
              stop("calibration curve doesn't exist\n", call.=FALSE)
  } else
  if(cc==1) fl <- "3Col_intcal20.14C" else
    if(cc==2) fl <- "3Col_marine20.14C" else
      if(cc==3) fl <- "3Col_shcal20.14C" else
        stop("calibration curve doesn't exist\n", call.=FALSE)
  cc <- system.file("extdata/Curves", fl, package='rbacon')
  cc <- read.table(cc)
  invisible(cc)
}



#' @name mix.curves
#' @title Build a custom-made, mixed calibration curve.
#' @description If two curves need to be `mixed' to calibrate, e.g. for dates of mixed terrestrial and marine carbon sources, then this function can be used.
#' @details The proportional contribution of each of both calibration curves has to be set.
#'
#' @param proportion Proportion of the first calibration curve required. e.g., change to \code{proportion=0.7} if \code{cc1} should contribute 70\% (and \code{cc2} 30\%) to the mixed curve.
#' @param cc1 The first calibration curve to be mixed. Defaults to the northern hemisphere terrestrial curve IntCal20.
#' @param cc2 The second calibration curve to be mixed. Defaults to the marine curve IntCal20.
#' @param name Name of the new calibration curve.
#' @param dirname Directory where the file will be written. If using the default \code{dirname="."},
#' the new curve will be saved in current working directory.
#' @param offset Any offset and error to be applied to \code{cc2} (default 0 +- 0).
#' @param sep Separator between fields (tab by default, "\\t")
#' @author Maarten Blaauw, J. Andres Christen
#' @return A file containing the custom-made calibration curve, based on calibration curves \code{cc1} and \code{cc2}.
#' @seealso \url{http://www.qub.ac.uk/chrono/blaauw/manualBacon_2.3.pdf}
#' @references
#' Blaauw, M. and Christen, J.A., Flexible paleoclimate age-depth models using an autoregressive
#' gamma process. Bayesian Anal. 6 (2011), no. 3, 457--474.
#' \url{https://projecteuclid.org/euclid.ba/1339616472}
#' @export
mix.curves <- function(proportion=.5, cc1="3Col_intcal20.14C", cc2="3Col_marine20.14C", name="mixed.14C", dirname=".", offset=c(0,0), sep="\t") {
  ccloc <- paste0(system.file("extdata", package='rbacon'), "/Curves/")
  dirname <- .validateDirectoryName(dirname)

  cc1 <- read.table(paste(ccloc, cc1,  sep=""))
  cc2 <- read.table(paste(ccloc, cc2,  sep=""))
  cc2.mu <- approx(cc2[,1], cc2[,2], cc1[,1], rule=2)$y + offset[1] # interpolate cc2 to the calendar years of cc1
  cc2.error <- approx(cc2[,1], cc2[,3], cc1[,1], rule=2)$y
  cc2.error <- sqrt(cc2.error^2 + offset[2]^2)
  mu <- proportion * cc1[,2] + (1-proportion) * cc2.mu
  error <- proportion * cc1[,3] + (1-proportion) * cc2.error
  write.table(cbind(cc1[,1], mu, error), paste0(dirname, name), row.names=FALSE, col.names=FALSE, sep=sep)
}



#' @name pMC.age
#' @title Calculate C14 ages from pMC values.
#' @description Calculate C14 ages from pMC values of radiocarbon dates.
#' @details Post-bomb dates are often reported as pMC or percent modern carbon. Since Bacon expects radiocarbon ages,
#'  this function can be used to calculate radiocarbon ages from pMC values. The reverse function is \link{age.pMC}.
#' @param mn Reported mean of the pMC.
#' @param sdev Reported error of the pMC.
#' @param ratio Most modern-date values are reported against \code{100}. If it is against \code{1} instead, use \code{1} here.
#' @param decimals Amount of decimals required for the radiocarbon age.
#' @author Maarten Blaauw, J. Andres Christen
#' @return Radiocarbon ages from pMC values. If pMC values are above 100\%, the resulting radiocarbon ages will be negative.
#' @examples
#'   pMC.age(110, 0.5) # a postbomb date, so with a negative 14C age
#'   pMC.age(80, 0.5) # prebomb dates can also be calculated
#'   pMC.age(.8, 0.005, 1) # pMC expressed against 1 (not against 100\%)
#' @seealso \url{http://www.qub.ac.uk/chrono/blaauw/manualBacon_2.3.pdf}
#' @references
#' Blaauw, M. and Christen, J.A., Flexible paleoclimate age-depth models using an autoregressive
#' gamma process. Bayesian Anal. 6 (2011), no. 3, 457--474.
#'  \url{https://projecteuclid.org/euclid.ba/1339616472}
#' @export
pMC.age <- function(mn, sdev, ratio=100, decimals=0) {
  y <- -8033 * log(mn/ratio)
  sdev <- y - -8033 * log((mn+sdev)/ratio)
  round(c(y, sdev), decimals)
}



#' @name age.pMC
#' @title Calculate pMC values from C14 ages
#' @description Calculate pMC values from radiocarbon ages
#' @details Post-bomb dates are often reported as pMC or percent modern carbon. Since Bacon expects radiocarbon ages,
#' this function can be used to calculate pMC values from radiocarbon ages. The reverse function of \link{pMC.age}.
#' @param mn Reported mean of the 14C age.
#' @param sdev Reported error of the 14C age.
#' @param ratio Most modern-date values are reported against \code{100}. If it is against \code{1} instead, use \code{1} here.
#' @param decimals Amount of decimals required for the pMC value.
#' @author Maarten Blaauw, J. Andres Christen
#' @return pMC values from C14 ages.
#' @examples
#'   age.pMC(-2000, 20)
#'   age.pMC(-2000, 20, 1)
#' @seealso \url{http://www.qub.ac.uk/chrono/blaauw/manualBacon_2.3.pdf}
#' @references
#' Blaauw, M. and Christen, J.A., Flexible paleoclimate age-depth models using an autoregressive
#' gamma process. Bayesian Anal. 6 (2011), no. 3, 457--474.
#' \url{https://projecteuclid.org/euclid.ba/1339616472}
#' @export
age.pMC <- function(mn, sdev, ratio=100, decimals=3) {
  y <- exp(-mn / 8033)
  sdev <- y - exp(-(mn + sdev) / 8033)
  signif(ratio*c(y, sdev), decimals)
}



#' @name add.dates
#' @title Add dates to age-depth plots
#' @description Add dated depths to plots, e.g. to show dates that weren't used in the age-depth model
#' @details Sometimes it is useful to add additional dating information to age-depth plots, e.g., to show outliers or how dates calibrate with different estimated offsets.
#' @param mn Reported mean of the date. Can be multiple dates.
#' @param sdev Reported error of the date. Can be multiple dates.
#' @param depth Depth of the date.
#' @param cc The calibration curve to use: \code{cc=1} for IntCal20 (northern hemisphere terrestrial), \code{cc=2} for Marine20 (marine), \code{cc=0} for none (dates that are already on the cal BP scale).
#' @param above Treshold for plotting of probability values. Defaults to \code{above=1e-3}.
#' @param ex Exaggeration of probability distribution plots. Defaults to \code{ex=50}.
#' @param normal By default, Bacon uses the student's t-distribution to treat the dates. Use \code{normal=TRUE} to use the normal/Gaussian distribution. This will generally give higher weight to the dates.
#' @param normalise By default, the date is normalised to an area of 1 (\code{normalise=TRUE}).
#' @param t.a The dates are treated using the student's t distribution by default (\code{normal=FALSE}).
#' The student's t-distribution has two parameters, t.a and t.b, set at 3 and 4 by default (see Christen and Perez, 2010).
#' If you want to assign narrower error distributions (more closely resembling the normal distribution), set t.a and t.b at for example 33 and 34 respectively (e.g., for specific dates in your .csv file).
#' For symmetry reasons, t.a must always be equal to t.b-1.
#' @param t.b The dates are treated using the student's t distribution by default (\code{normal=FALSE}).
#' The student's t-distribution has two parameters, t.a and t.b, set at 3 and 4 by default (see Christen and Perez, 2010).
#' If you want to assign narrower error distributions (more closely resembling the normal distribution), set t.a and t.b at for example 33 and 34 respectively (e.g., for specific dates in your .csv file).
#' For symmetry reasons, t.a must always be equal to t.b-1.
#' @param age.res Resolution of the date's distribution. Defaults to \code{date.res=100}.
#' @param times The extent of the range to be calculated for each date. Defaults to \code{times=20}.
#' @param col The colour of the ranges of the date. Default is semi-transparent red: \code{col=rgb(1,0,0,.5)}.
#' @param border The colours of the borders of the date. Default is semi-transparent red: \code{border=rgb(1,0,0,0.5)}.
#' @param rotate.axes The default of plotting age on the horizontal axis and event probability on the vertical one can be changed with \code{rotate.axes=TRUE}.
#' @param mirror Plot the dates as 'blobs'. Set to \code{mirror=FALSE} to plot simple distributions.
#' @param up Directions of distributions if they are plotted non-mirrored. Default \code{up=TRUE}.
#' @param BCAD The calendar scale of graphs is in \code{cal BP} by default, but can be changed to BC/AD using \code{BCAD=TRUE}.
#' @param pch The shape of any marker to be added to the date. Defaults to a cross, \code{pch=4}. To leave empty, use \code{pch=NA}.
#' @author Maarten Blaauw, J. Andres Christen
#' @return A date's distribution, added to an age-depth plot.
#' @seealso \url{http://www.qub.ac.uk/chrono/blaauw/manualBacon_2.3.pdf}
#' @references
#' Blaauw, M. and Christen, J.A., Flexible paleoclimate age-depth models using an autoregressive
#' gamma process. Bayesian Anal. 6 (2011), no. 3, 457--474.
#' \url{https://projecteuclid.org/euclid.ba/1339616472}
#' @export
add.dates <- function(mn, sdev, depth, cc=1, above=1e-6, ex=10, normal=TRUE, normalise=TRUE, t.a=3, t.b=4, age.res=100, times=20, col=rgb(1,0,0,.5), border=rgb(1,0,0,.5), rotate.axes=FALSE, mirror=TRUE, up=TRUE, BCAD=FALSE, pch=4) {
  if(cc > 0)
    cc <- copyCalibrationCurve(cc)

  for(i in 1:length(mn)) {
    yrs <- seq(mn[i]-times*sdev[i], mn[i]+times*sdev[i], length=age.res)
    if(length(cc) < 2)
      cc <- cbind(yrs, yrs, rep(0, length(yrs)))
    ages <- approx(cc[,1], cc[,2], yrs)$y
    errors <- approx(cc[,1], cc[,3], yrs)$y

  if(normal)
    probs <- dnorm(ages, mn[i], sqrt(sdev[i] + errors)^2) else
      probs <- (t.b + (mn[i]-ages)^2  / (2*(sdev[i]^2 + errors^2))) ^ (-1*(t.a+0.5))
  if(normalise)
    probs <- probs / sum(probs)
  these <- which(probs >= above)
  if(length(these) > 0) {
    yrs <- yrs[these]
    probs <- probs[these]
  }

  if(!up)
    up <- -1
  if(BCAD)
    yrs <- 1950 - yrs
  if(mirror)
    pol <- cbind(depth[i] + ex*c(probs, -rev(probs)), c(yrs, rev(yrs))) else
      pol <- cbind(depth[i] - up*ex*c(0, probs,  0), c(min(yrs), yrs, max(yrs)))
  if(rotate.axes)
    pol <- pol[,2:1]
  polygon(pol, col=col, border=border)
  if(length(pch) > 0)
    if(rotate.axes)
      points(mean(yrs), depth[i], col=border, pch=pch) else
        points(depth[i], mean(yrs), col=border, pch=pch)
  }
}



#' @name calib.plot
#' @title Plot the dates
#' @description Produce a plot of the dated depths and their dates
#' @details This function is generally called internally to produce the age-depth graph.
#' It can be used to produce custom-built graphs.
#' @param set Detailed information of the current run, stored within this session's memory as variable \code{info}.
#' @param BCAD The calendar scale of graphs is in \code{cal BP} by default, but can be changed to BC/AD using \code{BCAD=TRUE}.
#' @param cc Calibration curve to be used (defaults to info$cc)
#' @param rotate.axes The default of plotting age on the horizontal axis and event probability on the vertical one can be changed with \code{rotate.axes=TRUE}.
#' @param rev.d The direction of the depth axis can be reversed from the default (\code{rev.d=TRUE}).
#' @param rev.age The direction of the calendar age axis can be reversed from the default (\code{rev.age=TRUE})
#' @param rev.yr Deprecated - use rev.age instead
#' @param age.lim Minimum and maximum calendar age ranges, calculated automatically by default (\code{age.lim=c()}).
#' @param yr.lim Deprecated - use age.lim instead
#' @param d.lab The labels for the depth axis. Default \code{d.lab="Depth (cm)"}.
#' @param age.lab The labels for the calendar axis (default \code{yr.lab="cal BP"} or \code{"BC/AD"} if \code{BCAD=TRUE}).
#' @param yr.lab Deprecated - use age.lab instead
#' @param height The heights of the distributions of the dates. See also \code{normalise.dists}.
#' @param calheight Multiplier for the heights of the distributions of dates on the calendar scale. Defaults to \code{calheight=1}.
#' @param mirror Plot the dates as 'blobs'. Set to \code{mirror=FALSE} to plot simple distributions.
#' @param up Directions of distributions if they are plotted non-mirrored. Default \code{up=TRUE}.
#' @param cutoff Avoid plotting very low probabilities of date distributions (default \code{cutoff=0.001}).
#' @param date.res Date distributions are plotted using \code{date.res=100} points by default.
#' @param C14.col Colour of the calibrated distributions of the dates. Default is semi-transparent blue: \code{rgb(0,0,1,.35)}.
#' @param C14.border Colours of the borders of calibrated 14C dates. Default is transparent dark blue: cal.col
#' @param cal.col Colour of the non-14C dates in the age-depth plot: default semi-transparent blue-green: \code{rgb(0,.5,.5,.35)}.
#' @param cal.border Colour of the of the border of non-14C dates in the age-depth plot: default semi-transparent dark blue-green: \code{rgb(0,.5,.5,.5)}.
#' @param dates.col As an alternative to colouring dates based on whether they are 14C or not, sets of dates can be coloured as, e.g., \code{dates.col=colours()[2:100]}.
#' @param slump.col Colour of slumps. Defaults to \code{slump.col=grey(0.8)}.
#' @param new.plot Start a new plot (\code{new.plot=TRUE}) or plot over an existing plot (\code{new.plot=FALSE}).
#' @param plot.dists Plot the distributions of the dates (default \code{plot.dists=TRUE}).
#' @param same.heights Plot the distributions of the dates all at the same maximum height (default \code{same.height=FALSE}).
#' @param normalise.dists By default, the distributions of more precise dates will cover less time and will thus peak higher than less precise dates. This can be avoided by specifying \code{normalise.dists=FALSE}.
#' @author Maarten Blaauw, J. Andres Christen
#' @return NA
#' @seealso \url{http://www.qub.ac.uk/chrono/blaauw/manualBacon_2.3.pdf}
#' @references
#' Blaauw, M. and Christen, J.A., Flexible paleoclimate age-depth models using an autoregressive
#' gamma process. Bayesian Anal. 6 (2011), no. 3, 457--474.
#' \url{https://projecteuclid.org/euclid.ba/1339616472}
#' @export
### produce plots of the calibrated distributions
calib.plot <- function(set=get('info'), BCAD=set$BCAD, cc=set$cc, rotate.axes=FALSE, rev.d=FALSE, rev.age=FALSE, rev.yr=rev.age, age.lim=c(), yr.lim=age.lim, date.res=100, d.lab=c(), age.lab=c(), yr.lab=age.lab, height=15, calheight=1, mirror=TRUE, up=TRUE, cutoff=.001, C14.col=rgb(0,0,1,.5), C14.border=rgb(0,0,1,.75), cal.col=rgb(0,.5,.5,.5), cal.border=rgb(0,.5,.5,.75), dates.col=c(), slump.col=grey(0.8), new.plot=TRUE, plot.dists=TRUE, same.heights=FALSE, normalise.dists=TRUE) {
  height <- length(set$d.min:set$d.max) * height/50
  if(length(age.lim) == 0)
    lims <- c()
  for(i in 1:length(set$calib$probs))
    lims <- c(lims, set$calib$probs[[i]][,1])
  age.min <- min(lims)
  age.max <- max(lims)
  if(BCAD) {
    age.min <- 1950 - age.min
    age.max <- 1950 - age.max
    }
  if(length(age.lab) == 0)
    age.lab <- ifelse(set$BCAD, "BC/AD", paste("cal", set$age.unit, " BP"))
  age.lim <- extendrange(c(age.min, age.max), f=0.01)
  if(rev.age)
    age.lim <- age.lim[2:1]
  dlim <- range(set$elbows)
  if(rev.d)
    dlim <- dlim[2:1]
  if(length(d.lab) == 0)
    d.lab <- paste("depth (", set$depth.unit, ")", sep="")
  if(new.plot)
    if(rotate.axes)
      plot(0, type="n", xlim=age.lim, ylim=dlim[2:1], xlab=age.lab, ylab=d.lab, main="") else
        plot(0, type="n", xlim=dlim, ylim=age.lim, xlab=d.lab, ylab=age.lab, main="")

  if(length(set$slump) > 0)
    if(rotate.axes)
      abline(h=set$slump, lty=2, col=slump.col) else
        abline(v=set$slump, lty=2, col=slump.col)

  if(plot.dists)
    for(i in 1:length(set$calib$probs)) {
      cal <- cbind(set$calib$probs[[i]])
      d <- set$calib$d[[i]]
      if(BCAD)
        cal[,1] <- 1950-cal[,1]
      o <- order(cal[,1])
      cal <- cbind(cal[o,1], cal[o,2])
      if(same.heights)
        cal[,2] <- cal[,2]/max(cal[,2])
      if(normalise.dists)
        cal[,2] <- cal[,2]/sum(cal[,2])
      cal <- cal[cal[,2] >= cutoff,]
      cal[,2] <- height*cal[,2]
      if(ncol(set$dets) > 4 && set$dets[i,5] == 0) # cal BP date
        cal[,2] <- calheight*cal[,2]
      cal <- approx(cal[,1], cal[,2], seq(min(cal[,1]), max(cal[,1]), length=100)) # tmp

      if(mirror)
        pol <- cbind(c(d-cal$y, d+rev(cal$y)), c(cal$x, rev(cal$x))) else
         if(up)
           pol <- cbind(d-c(0, cal$y, 0), c(min(cal$x), cal$x, max(cal$x))) else
             pol <- cbind(d+c(0, cal$y, 0), c(min(cal$x), cal$x, max(cal$x)))
      if(rotate.axes)
        pol <- cbind(pol[,2], pol[,1])
      if(ncol(set$dets)==4 && cc > 0 || (ncol(set$dets) > 4 && set$dets[i,5] > 0)) {
        col <- C14.col
        border <- C14.border
      } else {
          col <- cal.col
          border <- cal.border
        }
      if(length(dates.col) > 0) {
        col <- dates.col[i]
        border <- dates.col[i]
      }
      polygon(pol, col=col, border=border)
    }
}


# calibrate C14 dates and calculate distributions for any calendar dates
.bacon.calib <- function(dat, set=get('info'), date.res=100, normal=set$normal, t.a=set$t.a, t.b=set$t.b, delta.R=set$delta.R, delta.STD=set$delta.STD, ccdir="") {
  # read in the curves
  if(set$cc1=="IntCal20" || set$cc1=="\"IntCal20\"")
    cc1 <- read.table(paste(ccdir, "3Col_intcal20.14C",sep="")) else
      cc1 <- read.csv(paste(ccdir, set$cc1, ".14C", sep=""), header=FALSE, skip=11)[,1:3]
  if(set$cc2=="Marine20" || set$cc2=="\"Marine20\"")
    cc2 <- read.table(paste(ccdir, "3Col_marine20.14C",sep="")) else
      cc2 <- read.csv(paste(ccdir, set$cc2, ".14C", sep=""), header=FALSE, skip=11)[,1:3]
  if(set$cc3=="SHCal20" || set$cc3=="\"SHCal20\"")
    cc3 <- read.table(paste(ccdir, "3Col_shcal20.14C",sep="")) else
      cc3 <- read.csv(paste(ccdir, set$cc3, ".14C", sep=""), header=FALSE, skip=11)[,1:3]
  if(set$cc4=="ConstCal" || set$cc4=="\"ConstCal\"") cc4 <- NA else
    cc4 <- read.table(paste(ccdir, set$cc4, sep=""))[,1:3]

  if(set$postbomb != 0) {
    if(set$postbomb==1) bomb <- read.table(paste(ccdir,"postbomb_NH1.14C", sep=""))[,1:3] else
      if(set$postbomb==2) bomb <- read.table(paste(ccdir,"postbomb_NH2.14C", sep=""))[,1:3] else
        if(set$postbomb==3) bomb <- read.table(paste(ccdir,"postbomb_NH3.14C", sep=""))[,1:3] else
          if(set$postbomb==4) bomb <- read.table(paste(ccdir,"postbomb_SH1-2.14C", sep=""))[,1:3] else
            if(set$postbomb==5) bomb <- read.table(paste(ccdir,"postbomb_SH3.14C", sep=""))[,1:3] else
              stop("cannot find postbomb curve #", set$postbomb, " (use values of 1 to 5 only)", call.=FALSE)
      bomb.x <- seq(max(bomb[,1]), min(bomb[,1]), by=-.1) # interpolate
      bomb.y <- approx(bomb[,1], bomb[,2], bomb.x)$y
      bomb.z <- approx(bomb[,1], bomb[,3], bomb.x)$y
      bomb <- cbind(bomb.x, bomb.y, bomb.z, deparse.level=0)
      if(set$postbomb < 4)
        cc1 <- rbind(bomb, cc1, deparse.level=0) else
          cc3 <- rbind(bomb, cc3, deparse.level=0)
  }

  ## use Gaussian or t (Christen and Perez Radiocarbon 2009) calibration
  if(round(set$t.b-set$t.a) !=1)
    stop("t.b - t.a should always be 1, check the manual", call.=FALSE)

  d.cal <- function(cc, rcmean, w2, t.a, t.b) {
    if(set$normal)
      cal <- cbind(cc[,1], dnorm(cc[,2], rcmean, sqrt(cc[,3]^2+w2))) else
        cal <- cbind(cc[,1], (t.b+ ((rcmean-cc[,2])^2) / (2*(cc[,3]^2 + w2))) ^ (-1*(t.a+0.5))) # student-t
    cal[,2] <- cal[,2]/sum(cal[,2])
    if(length(which(cal[,2]>set$cutoff)) > 5) # ensure that also very precise dates get a range of probabilities
      cal[which(cal[,2]>set$cutoff),] else {
        calx <- seq(min(cal[,1]), max(cal[,1]), length=100)
        caly <- approx(cal[,1], cal[,2], calx)$y
        cbind(calx, caly/sum(caly), deparse.level = 0)
      }
  }

  # now calibrate all dates
  calib <- list(d=dat[,4])
  if(ncol(dat)==4) { # only one type of dates (e.g., calBP, or all IntCal20 C14 dates)
    if(set$cc==0) {
      x <- seq(min(dat[,2])-(5*max(dat[,3])), max(dat[,2])+(5*max(dat[,3])), by=5) # simplify, May 2019
      if(length(x) > 100) # if too many resulting years, make 100 vals
        x <- seq(min(dat[,2])-(5*max(dat[,3])), max(dat[,2])+(5*max(dat[,3])), length=100)
      ccurve <- cbind(x, x, rep(0,length(x))) # dummy 1:1 curve
    } else {
        if(set$cc==1) ccurve <- cc1 else
          if(set$cc==2) ccurve <- cc2 else
            if(set$cc==3) ccurve <- cc3 else
              ccurve <- cc4
      }
    for(i in 1:nrow(dat))
      calib$probs[[i]] <- d.cal(ccurve, dat[i,2]-delta.R, dat[i,3]^2+delta.STD^2, set$t.a, set$t.b)
  } else
      for(i in 1:nrow(dat)) {
        dets <- c(NA, as.numeric(dat[i,-1])) # first entry is often not numeric
        if(dets[5]==0) {
          x <- seq(dets[2]-(5*dets[3]), dets[2]+(5*dets[3]), by=5) # simplify, May 2019
          if(length(x) < 5 || length(x) > 100) # if too many resulting years, make 100 vals
            x <- seq(dets[2]-(5*dets[3]), dets[2]+(5*dets[3]), length=100)
          ccurve <- cbind(x, x, rep(0,length(x))) # dummy 1:1 curve
        } else
            if(dets[5]==1) ccurve <- cc1 else if(dets[5]==2) ccurve <- cc2 else
              if(dets[5]==3) ccurve <- cc3 else ccurve <- cc4

        delta.R <- set$delta.R; delta.STD <- set$delta.STD; t.a <- set$t.a; t.b <- set$t.b
        if(length(dets) >= 7 && dets[5] > 0) { # the user provided age offsets; only for C14 dates
          delta.R <- dets[6]
          delta.STD <- dets[7]
        }

        if(length(dets) >= 9) { # the user provided t.a and t.b values for each date
          t.a <- dets[8]
          t.b <- dets[9]
          if(round(t.b-t.a) != 1)
            stop("t.b - t.a should always be 1, check the manual", call.=FALSE)
        }
        calib$probs[[i]] <- d.cal(ccurve, dets[2]-delta.R, dets[3]^2+delta.STD^2, t.a, t.b)
      }
  calib
}


### for running Plum, but is looked for by generic agedepth() function, so is included in the rbacon code
#' @name calib.plumbacon.plot
#' @title Plot the dates
#' @description Produce a plot of the dated depths and their dates
#' @details This function is generally called internally to produce the age-depth graph.
#' It can be used to produce custom-built graphs.
#' @param set Detailed information of the current run, stored within this session's memory as variable \code{info}.
#' @param BCAD The calendar scale of graphs is in \code{cal BP} by default, but can be changed to BC/AD using \code{BCAD=TRUE}.
#' @param cc Calibration curve to be used (defaults to info$cc)
#' @param firstPlot description
#' @param rotate.axes The default of plotting age on the horizontal axis and event probability on the vertical one can be changed with \code{rotate.axes=TRUE}.
#' @param rev.d The direction of the depth axis can be reversed from the default (\code{rev.d=TRUE}).
#' @param rev.age The direction of the calendar age axis can be reversed from the default (\code{rev.age=TRUE})
#' @param rev.yr Deprecated - use rev.age instead
#' @param age.lim Minimum and maximum calendar age ranges, calculated automatically by default (\code{age.lim=c()}).
#' @param yr.lim Deprecated - use age.lim instead
#' @param d.lab The labels for the depth axis. Default \code{d.lab="Depth (cm)"}.
#' @param age.lab The labels for the calendar axis (default \code{yr.lab="cal BP"} or \code{"BC/AD"} if \code{BCAD=TRUE}).
#' @param yr.lab Deprecated - use age.lab instead
#' @param height The heights of the distributions of the dates. See also \code{normalise.dists}.
#' @param calheight Multiplier for the heights of the distributions of dates on the calendar scale. Defaults to \code{calheight=1}.
#' @param mirror Plot the dates as 'blobs'. Set to \code{mirror=FALSE} to plot simple distributions.
#' @param up Directions of distributions if they are plotted non-mirrored. Default \code{up=TRUE}.
#' @param cutoff Avoid plotting very low probabilities of date distributions (default \code{cutoff=0.001}).
#' @param date.res Date distributions are plotted using \code{date.res=100} points by default.
#' @param C14.col Colour of the calibrated distributions of the dates. Default is semi-transparent blue: \code{rgb(0,0,1,.35)}.
#' @param C14.border Colours of the borders of calibrated 14C dates. Default is transparent dark blue: cal.col
#' @param cal.col Colour of the non-14C dates in the age-depth plot: default semi-transparent blue-green: \code{rgb(0,.5,.5,.35)}.
#' @param cal.border Colour of the of the border of non-14C dates in the age-depth plot: default semi-transparent dark blue-green: \code{rgb(0,.5,.5,.5)}.
#' @param dates.col As an alternative to colouring dates based on whether they are 14C or not, sets of dates can be coloured as, e.g., \code{dates.col=colours()[2:100]}.
#' @param slump.col Colour of slumps. Defaults to \code{slump.col=grey(0.8)}.
#' @param new.plot Start a new plot (\code{new.plot=TRUE}) or plot over an existing plot (\code{new.plot=FALSE}).
#' @param plot.dists Plot the distributions of the dates (default \code{plot.dists=TRUE}).
#' @param same.heights Plot the distributions of the dates all at the same maximum height (default \code{same.height=FALSE}).
#' @param normalise.dists By default, the distributions of more precise dates will cover less time and will thus peak higher than less precise dates. This can be avoided by specifying \code{normalise.dists=FALSE}.
#' @author Maarten Blaauw, J. Andres Christen
#' @return NA
#' @seealso \url{http://www.qub.ac.uk/chrono/blaauw/manualBacon_2.3.pdf}
#' @references
#' Blaauw, M. and Christen, J.A., Flexible paleoclimate age-depth models using an autoregressive
#' gamma process. Bayesian Anal. 6 (2011), no. 3, 457--474.
#' \url{https://projecteuclid.org/euclid.ba/1339616472}
#' @export
### produce plots of the calibrated distributions
calib.plumbacon.plot <- function(set=get('info'), BCAD=set$BCAD, cc=set$cc, firstPlot = FALSE, rotate.axes=FALSE, rev.d=FALSE, rev.age=FALSE, rev.yr=rev.age, age.lim=c(), yr.lim=age.lim, date.res=100, d.lab=c(), age.lab=c(), yr.lab=age.lab, height=15, calheight=1, mirror=TRUE, up=TRUE, cutoff=.001, C14.col=rgb(0,0,1,.5), C14.border=rgb(0,0,1,.75), cal.col=rgb(0,.5,.5,.5), cal.border=rgb(0,.5,.5,.75), dates.col=c(), slump.col=grey(0.8), new.plot=TRUE, plot.dists=TRUE, same.heights=FALSE, normalise.dists=TRUE) {
  height <- length(set$d.min:set$d.max) * height/50
  if(length(age.lim) == 0)
    lims <- c()
  for(i in 1:length(set$calib$probs))
    lims <- c(lims, set$calib$probs[[i]][,1])
  age.min <- min(lims)
  age.max <- max(lims)
  if(BCAD) {
    age.min <- 1950 - age.min
    age.max <- 1950 - age.max
    }
  if(length(age.lab) == 0)
    age.lab <- ifelse(set$BCAD, "BC/AD", paste("cal", set$age.unit, " BP"))
  age.lim <- extendrange(c(age.min, age.max), f=0.01)
  if(rev.age)
    age.lim <- age.lim[2:1]
  dlim <- range(set$elbows)
  if(rev.d)
    dlim <- dlim[2:1]
  if(length(d.lab) == 0)
    d.lab <- paste("depth (", set$depth.unit, ")", sep="")

  if(new.plot)
    if(rotate.axes)
      plot(0, type="n", xlim=age.lim, ylim=dlim[2:1], xlab=age.lab, ylab=d.lab, main="") else
        plot(0, type="n", xlim=dlim, ylim=age.lim, xlab=d.lab, ylab=age.lab, main="")

  if(length(set$slump) > 0)
    if(rotate.axes)
      abline(h=set$slump, lty=2, col=slump.col) else
        abline(v=set$slump, lty=2, col=slump.col)

  if(plot.dists)
    for(i in 1:length(set$calib$probs)) {
      if( set$dets[i,9] != 5 ){
        cal <- cbind(set$calib$probs[[i]])
        d <- set$calib$d[[i]]
        if(BCAD)
          cal[,1] <- 1950-cal[,1]
        o <- order(cal[,1])
        cal <- cbind(cal[o,1], cal[o,2])
        if(same.heights)
          cal[,2] <- cal[,2]/max(cal[,2])
        if(normalise.dists)
          cal[,2] <- cal[,2]/sum(cal[,2])
        cal <- cal[cal[,2] >= cutoff,]
        cal[,2] <- height*cal[,2]
        if(ncol(set$dets) > 4 && set$dets[i,9] == 0) # cal BP date
          cal[,2] <- calheight*cal[,2]

        x = cal[,1]
        y = cal[,2]

        y = y[!duplicated(x)]
        x = x[!duplicated(x)]
        #seq(min(cal[,1]), max(cal[,1]), length= length(cal[,1]) )
        cal <- approx(x, y, seq(min(x), max(x), length= 100 ) ) # tmp

        if(mirror)
          pol <- cbind(c(d-cal$y, d+rev(cal$y)), c(cal$x, rev(cal$x)))
        else if(up)
          pol <- cbind(d-c(0, cal$y, 0), c(min(cal$x), cal$x, max(cal$x)))
        else
          pol <- cbind(d+c(0, cal$y, 0), c(min(cal$x), cal$x, max(cal$x)))
        if(rotate.axes)
          pol <- cbind(pol[,2], pol[,1])
        if(ncol(set$dets)==4 && cc > 0 || (ncol(set$dets) > 4 && set$dets[i,9] > 0)) {
          col <- C14.col
          border <- C14.border
        } else {
          col <- cal.col
          border <- cal.border
        }
        if(length(dates.col) > 0) {
          col <- dates.col[i]
          border <- dates.col[i]
        }
        polygon(pol, col=col, border=border)
      }
    }

}



### for running Plum, but is looked for by generic agedepth() function, so is included in the rbacon code
#' @name draw.pbmodelled
#' @title Plot the 210Pb data
#' @description Produce a plot of the 210Pb data and their depths
#' @details This function is generally called internally to produce the age-depth graph.
#' It can be used to produce custom-built graphs.
#' @param set Detailed information of the current run, stored within this session's memory as variable \code{info}.
#' @param BCAD The calendar scale of graphs is in \code{cal BP} by default, but can be changed to BC/AD using \code{BCAD=TRUE}.
#' @param rotate.axes The default of plotting age on the horizontal axis and event probability on the vertical one can be changed with \code{rotate.axes=TRUE}.
#' @param rev.d The direction of the depth axis can be reversed from the default (\code{rev.d=TRUE}).
#' @param pb.lim Minimum and maximum of the 210Pb axis ranges, calculated automatically by default (\code{pb.lim=c()}).
#' @param d.lim Minimum and maximum depths to plot; calculated automatically by default (\code{d.lim=c()}).
#' @param d.lab The labels for the depth axis. Default \code{d.lab="Depth (cm)"}.
#' @param pb.lab The label for the 210Pb axis (default \code{pb.lab="210Pb (Bq/kg)"} or \code{"210Pb (dpm/g)"}).
#' @param pbmeasured.col Colour of the measured 210Pb data. Defaults to blue: \code{pbmeasured.col="blue"}.
#' @param pbmodelled.col Colour of the modelled 210Pb data. Defaults to shades of blue: \code{pbmodelled.col=function(x) rgb(0,0,1,x)}.
#' @param supp.col Colour of the supported 210Pb data. Defaults to red: \code{supp.col="red"}.
#' @param plot.measured Plot the measured 210Pb values (default \code{plot.measured=TRUE}).
#' @param age.lim values of the age axis. Used to calculate where to plot the pb values on the secondary axis
#' @author Maarten Blaauw, J. Andres Christen, Marco Aquino-Lopez
#' @return A plot of the modelled (and optionally the measured) 210Pb values
#' @export
draw.pbmodelled <- function(set=get('info'), BCAD=set$BCAD, rotate.axes=FALSE, rev.d=FALSE, pb.lim=c(), d.lim=c(), d.lab=c(), pb.lab=c(), pbmodelled.col=function(x) rgb(0,0,1,x), pbmeasured.col="blue", supp.col="red", plot.measured=TRUE, age.lim=c()) {
  depths <- set$detsOrig[,2]
  dns <- set$detsOrig[,3]
  Pb <- set$detsOrig[,4]
  err <- set$detsOrig[,5]
  thickness <- set$detsOrig[,6]
  n <- nrow(set$detsOrig)

  if(ncol(set$detsPlum) > 6) {
    supp <- set$detsOrig[,7]
    supperr <- set$detsOrig[,8]
  }

  if(length(d.lab) == 0)
    d.lab <- paste("depth (", set$depth.unit, ")", sep="")
  if(length(pb.lab) == 0)
    pb.lab <- ifelse(set$Bqkg, "210Pb (Bq/kg)", "210Pb (dpm/g)")    

  if(length(d.lim) == 0)
    d.lim <- range(depths)
  if(rev.d)
    d.lim <- d.lim[2:1]
   
  if(length(set$phi) > 0) {
    Ai <- list(x=c(), y=c())
    hght <- 0; pbmin <- c(); pbmax <- 0
    A.rng <- array(0, dim=c(n,2))
    for(i in 1:length(depths)) {
      A <- A.modelled(depths[i]-thickness[i], depths[i], dns[i], set)
      if(!is.numeric(A)) 
        A <- c(0,0) # as ugly as an owl with just one ear!
      tmp <- density(A)
      Ai$x[[i]] <- tmp$x
      Ai$y[[i]] <- tmp$y
      hght <- max(hght, Ai$y[[i]])
      pbmin <- min(pbmin, Ai$y[[i]], na.rm=TRUE)
      pbmax <- max(pbmax, Ai$x[[i]], na.rm=TRUE)
      A.rng[i,] <- quantile(A, c((1-set$prob)/2, 1-(1-set$prob)/2))
    } 
 
    if(length(pb.lim) == 0) 
      pb.lim <- extendrange(c(0, Pb-2*err, Pb+2*err, pbmax), f=c(0,0.05))
 
    # translate pb values to cal BP (or BC/AD?) values for plotting on the age axis. 
    pb2bp <- function(pb, pb.min=pb.lim[1], pb.max=pb.lim[2], agemin=age.lim[1], agemax=age.lim[2]) {
      ex <- (agemax-agemin) / (pb.max - pb.min)
      agemin + ex*pb
    }      
      
    # save the values for later; DOESN'T WORK and I don't understand why not
    set$Ai <- Ai
    set$A.rng <- A.rng
    .assign_to_global("info", set)
  
    ax <- ifelse(rotate.axes, 3, 4) 
    pretty.pb <- pretty(c(pbmin, pbmax))
    onbp <- pb2bp(pretty.pb)
    pb.lab <- ifelse(set$Bq, "Bq/kg", "dpm/g")
    axis(ax, onbp, pretty.pb, col=pbmeasured.col, col.axis=pbmeasured.col, col.lab=pbmeasured.col)
    mtext(pb.lab, ax, 1.4, col=pbmeasured.col, cex=.8)

    for(i in 1:length(depths)) {
      age <- pb2bp( Ai$x[[i]] )
      z <- t( Ai$y[[i]] )/hght # normalise to the densest point
#      if(BCAD) {
 #       z <- t(rev( Ai$y[[i]] ))/hght
  #      age <- rev(age)
   #   }
    depth <- c(depths[i]-thickness[i], depths[i])

      if(rotate.axes)
        image(age, depth, t(z), col=pbmodelled.col(seq(0, 1-max(z), length=50)),  add=TRUE) else
          image(depth, age, z, col=pbmodelled.col(seq(0, 1-max(z), length=50)), add=TRUE) 
    }
  }

  if(plot.measured) {
    if(rotate.axes)
      rect(pb2bp(Pb-err), depths, pb2bp(Pb+err), depths-thickness, 
        border=pbmeasured.col, lty=3) else
          rect(depths, pb2bp(Pb-err), depths-thickness, pb2bp(Pb+err),
            border=pbmeasured.col, lty=3)

    if(ncol(set$detsOrig) > 6) {
      supp <- set$detsOrig[,7]
      supperr <- set$detsOrig[,8]
      if(rotate.axes)
        rect(pb2bp(supp-supperr), depths-thickness, pb2bp(supp+supperr), depths,
          border=supp.col, lty=3) else
          rect(depths-thickness, pb2bp(supp-supperr), depths, pb2bp(supp+supperr), 
            border=supp.col, lty=3)
    }
  }
}



### for running Plum, but is looked for by generic agedepth() function, so is included in the rbacon code
#' @name A.modelled
#' @title Calculate modelled 210Pb
#' @description Calculate modelled 210Pb values of a sample slice, based on the parameters of the age-model (i.e., time passed since deposition of the bottom and top of the slice), supported and influx
#' @param d.top top depth of the slice
#' @param d.bottom bottom depth of the slice
#' @param dens Density of the slice (in g/cm3)
#' @param set Detailed information of the current run, stored within this session's memory as variable \code{info}.
#' @param phi The modelled values of the 210Pb influx
#' @param sup The modelled values of the supported 210Pb
#' @author Maarten Blaauw
#' @return a list of modelled values of A
#' @export
A.modelled <- function(d.top, d.bottom, dens, set=get('info'), phi=set$phi, sup=set$ps) {
  if(d.top >= d.bottom)
    stop("\n d.top should be higher than d.bottom", call.=FALSE)
  t.top <- Bacon.Age.d(d.top, BCAD=F) - set$theta0
  t.bottom <- Bacon.Age.d(d.bottom, BCAD=F) - set$theta0
  multiply <- 500
  if(set$Bqkg)
	multiply <- 10  
  return(sup + ((phi / (.03114*multiply*dens) ) * (exp( -.03114*t.top) - exp(-.03114*t.bottom)) ) )
} 



% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calibrate.R
\name{copyCalibrationCurve}
\alias{copyCalibrationCurve}
\title{Copy a calibration curve.}
\usage{
copyCalibrationCurve(cc = 1, postbomb = FALSE)
}
\arguments{
\item{cc}{Calibration curve for 14C dates: \code{cc=1} for IntCal20 (northern hemisphere terrestrial), \code{cc=2} for Marine20 (marine),
\code{cc=3} for SHCal20 (southern hemisphere terrestrial).}

\item{postbomb}{Use \code{postbomb=TRUE} to get a postbomb calibration curve (default \code{postbbomb=FALSE}).}
}
\value{
The calibration curve (invisible).
}
\description{
Copy one of the the calibration curves into memory.
}
\details{
Copy the radiocarbon calibration curve defined by cc into memory.
}
\seealso{
\url{http://www.qub.ac.uk/chrono/blaauw/manualBacon_2.3.pdf}
}
\author{
Maarten Blaauw, J. Andres Christen
}

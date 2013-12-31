context("topographic_corr routines")

suppressMessages(library(landsat))

# Load sample data
L5TSR_1986_b1 <- raster(L5TSR_1986, layer=1)
L5TSR_1986_b2 <- raster(L5TSR_1986, layer=2)
DEM_mosaic <- mosaic(ASTER_V002_EAST, ASTER_V002_WEST, fun='mean')
matched_DEM <- suppressMessages(match_rasters(L5TSR_1986, DEM_mosaic))
slopeaspect <- slopeasp_seq(matched_DEM)
slope <- as(raster(slopeaspect, layer=1), "SpatialGridDataFrame")
aspect <- as(raster(slopeaspect, layer=2), "SpatialGridDataFrame")
sunelev <- 90 - 44.97 # From metadata file
sunazimuth <- 124.37 # From metadata file

# Override teamr topographic_corr with a local version that suppresses messages
topographic_corr <- function(...) {
    suppressMessages(teamr::topographic_corr(...))
}

###############################################################################
# Test that minslope methods match between landsat package 'topocorr' and teamr 
# 'topographic_corr':
teamr_tc <- topographic_corr(L5TSR_1986_b1, slopeaspect, sunelev, sunazimuth, 
                             method='minslope')

landsat_tc_b1 <- topocorr(as(L5TSR_1986_b1, "SpatialGridDataFrame"), slope, 
                          aspect, sunelev, sunazimuth, method='minslope')
landsat_tc_b1 <- raster(landsat_tc_b1)
names(landsat_tc_b1) <- 'b1tc'

test_that("teamr and landsat minslope match", {
          expect_equal(teamr_tc, expected=landsat_tc_b1)
})

###############################################################################
set.seed(1)
sampleindices <- gridsample(L5TSR_1986_b1, rowmajor=TRUE)
teamr_tc_sample <- topographic_corr(L5TSR_1986_b1, slopeaspect, sunelev, 
                                    sunazimuth, method='minslope', 
                                    sampleindices=sampleindices)

test_that("teamr and landsat minslope match when sampling is used in teamr", {
          expect_equal(teamr_tc_sample, expected=landsat_tc_b1, tolerance=.25)
})

###############################################################################
landsat_tc_b2 <- topocorr(as(L5TSR_1986_b2, "SpatialGridDataFrame"), slope, 
                          aspect, sunelev, sunazimuth, method='minslope')
landsat_tc_b2 <- raster(landsat_tc_b2)
names(landsat_tc_b2) <- 'b2tc'
landsat_tc_b1_b2 <- stack(landsat_tc_b1, landsat_tc_b2)

teamr_tc_b1_b2 <- topographic_corr(stack(L5TSR_1986_b1, L5TSR_1986_b2),
                                   slopeaspect, sunelev, sunazimuth, 
                                   method='minslope')

test_that("teamr and landsat minslope match when multiple layers are processed in teamr", {
          expect_equal(teamr_tc_b1_b2, expected=landsat_tc_b1_b2)
})

###############################################################################
# Test that minnaert_full methods match between landsat package 'topocorr' and 
# teamr 'topographic_corr' when using full image.
teamr_minnaert <- topographic_corr(L5TSR_1986_b1, slopeaspect, sunelev, 
                                   sunazimuth, method='minnaert_full')

landsat_minnaert <- minnaert(as(L5TSR_1986_b1, "SpatialGridDataFrame"), slope, 
                             aspect, sunelev, sunazimuth)
landsat_minnaert <- raster(landsat_minnaert$minnaert)
names(landsat_minnaert) <- 'b1tc'

test_that("teamr minnaert and landsat minnaert match", {
          expect_equal(teamr_minnaert, expected=landsat_minnaert)
})

###############################################################################
# Test that minnaert_full methods match between landsat package 'topocorr' and 
# teamr 'topographic_corr' when using resampling.
set.seed(0)
sampleindices <- gridsample(L5TSR_1986_b1, rowmajor=TRUE)
teamr_minnaert_sample <- topographic_corr(L5TSR_1986_b1, slopeaspect, sunelev, 
                                   sunazimuth, method='minnaert_full',
                                   sampleindices=sampleindices)

test_that("teamr minnaert sample and landsat minnaert match", {
          expect_equal(teamr_minnaert_sample, expected=landsat_minnaert, 
                       tolerance=.25)
})

###############################################################################
# Test that minnaert_full methods match when teamr minnaert_full runs 
# sequentially or in parallel.
suppressMessages(library(spatial.tools))
set.seed(0)
sampleindices <- gridsample(L5TSR_1986_b1, rowmajor=TRUE)
sfQuickInit(2)

teamr_minnaert_sample_b1b2 <- topographic_corr(stack(L5TSR_1986_b1, L5TSR_1986_b2),
                                              slopeaspect, sunelev, sunazimuth, 
                                              method='minnaert_full',
                                              sampleindices=sampleindices)

teamr_minnaert_sample_b1b2_par <- topographic_corr(stack(L5TSR_1986_b1, L5TSR_1986_b2),
                                              slopeaspect, sunelev, sunazimuth, 
                                              method='minnaert_full',
                                              sampleindices=sampleindices,
                                              inparallel=TRUE)
sfQuickStop(2)

test_that("teamr minnaert sample and landsat minnaert match", {
          expect_equal(teamr_minnaert_sample_b1b2, expected=teamr_minnaert_sample_b1b2_par)
})
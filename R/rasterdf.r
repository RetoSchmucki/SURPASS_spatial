rasterdf <- function(x, aggregate = 1) {
    resampleFactor <- aggregate        
    inputRaster <- x    
    inCols <- ncol(inputRaster)
    inRows <- nrow(inputRaster)
    # Compute numbers of columns and rows in the new raster for mapping
    resampledRaster <- rast(ncol=(inCols / resampleFactor), 
                            nrow=(inRows / resampleFactor))
    # Match to the extent of the original raster
    ext(resampledRaster) <- ext(inputRaster)
    # Resample data on the new raster
    y <- resample(inputRaster, resampledRaster, method = 'near')

    # Extract cell coordinates  
    coords <- xyFromCell(y, seq_len(ncell(y)))
    dat <- stack(as.data.frame(values(y)))
    # Add names - 'value' for data, 'variable' to indicate different raster layers
    # in a stack
    names(dat) <- c('value', 'variable')
    dat <- cbind(coords, dat)
    dat
    }
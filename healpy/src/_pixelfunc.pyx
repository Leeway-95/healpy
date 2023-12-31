# Wrapper around the geometry methods in Healpix_base class

import numpy as np
cimport numpy as np
from libcpp cimport bool
cimport cython
from _common cimport int64, Healpix_Ordering_Scheme, RING, NEST, SET_NSIDE, T_Healpix_Base

from .pixelfunc import isnsideok

def ringinfo(nside, np.ndarray[int64, ndim=1] ring not None):
    """Get information for rings

    Rings are specified by a positive integer, 1 <= ring <= 4*nside-1.

    Parameters
    ----------
    nside : int
      The healpix nside parameter, must be a power of 2, less than 2**30
    ring : 1d numpy array
      The ring number

    Returns
    -------
    startpix : int64, length equal to that of *ring*
      Starting pixel identifier (NEST ordering)
    ringpix : int64, length equal to that of *ring*
      Number of pixels in ring
    costheta : float, length equal to that of *ring*
      Cosine of the co-latitude
    sintheta : float, length equal to that of *ring*
      Sine of the co-latitude
    shifted : bool, length equal to that of *ring*
      If True, the center of the first pixel is not at phi=0

    Example
    -------
    >>> import healpy as hp
    >>> import numpy as np
    >>> nside = 2
    >>> hp.ringinfo(nside, np.arange(1, 4*nside))
    (array([ 0,  4, 12, 20, 28, 36, 44]),
     array([4, 8, 8, 8, 8, 8, 4]),
     array([ 0.91666667,  0.66666667,  0.33333333,  0.        , -0.33333333,
            -0.66666667, -0.91666667]),
     array([0.39965263, 0.74535599, 0.94280904, 1.        , 0.94280904,
            0.74535599, 0.39965263]),
     array([ True,  True, False,  True, False,  True,  True]))
    """
    if not isnsideok(nside, nest=False):
        raise ValueError('Wrong nside value, must be a power of 2, less than 2**30')
    cdef Healpix_Ordering_Scheme scheme = NEST
    cdef T_Healpix_Base[int64] hb = T_Healpix_Base[int64](nside, scheme, SET_NSIDE)
    num = ring.shape[0]
    cdef np.ndarray[int64, ndim=1] startpix = np.empty(num, dtype=np.int64)
    cdef np.ndarray[int64, ndim=1] ringpix = np.empty(num, dtype=np.int64)
    cdef np.ndarray[double, ndim=1] costheta = np.empty(num, dtype=np.float64)
    cdef np.ndarray[double, ndim=1] sintheta = np.empty(num, dtype=np.float64)
    cdef np.ndarray[bool, ndim=1, cast=True] shifted = np.empty(num, dtype=np.bool_)
    for i in range(num):
        hb.get_ring_info(ring[i], startpix[i], ringpix[i], costheta[i], sintheta[i], shifted[i])
    return startpix, ringpix, costheta, sintheta, shifted

def pix2ring(nside, np.ndarray[int64, ndim=1] pix not None, nest=False):
    """Convert pixel identifier to ring number

    Rings are specified by a positive integer, 1 <= ring <= 4*nside-1.

    Parameters
    ----------
    nside : int
      The healpix nside parameter, must be a power of 2, less than 2**30
    pix : int64, scalar or array-like
      The pixel identifier(s)
    nest : bool
      Is *pix* specified in the NEST ordering scheme?

    Returns
    -------
    ring : int, length equal to that of *pix*
      Ring number

    Example
    -------
    >>> import healpy as hp
    >>> import numpy as np
    >>> nside = 2
    >>> hp.pix2ring(nside, np.arange(hp.nside2npix(nside)))
    array([1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4,
           4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7,
           7, 7])
    """

    if not isnsideok(nside, nest=nest):
        raise ValueError('Wrong nside value, must be a power of 2 (for nested), less than 2**30')
    cdef T_Healpix_Base[int64] hb = T_Healpix_Base[int64](nside, NEST if nest else RING, SET_NSIDE)
    num = pix.shape[0]
    cdef np.ndarray[int64, ndim=1] ring = np.empty(num, dtype=np.int64)
    for i in range(num):
        ring[i] = hb.pix2ring(pix[i])
    return ring

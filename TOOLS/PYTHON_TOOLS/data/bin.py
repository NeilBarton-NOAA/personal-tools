###############################################################################################################
# Neil P. Barton
# February 8, 2011 2:51:33 PM PST
###############################################################################################################
def getdata(file_name, dtype, mult = 1.0, shape = False, order = 'F', offset = 0):
	"""
	uses the numpy.memmap program to read binary data into python
	INPUT
		file_name:	name of file name
		dtype:		data type of binary file, no default,must be a string
		mult:			what the data need to be multipled by, default is 1
		shape:		shape of data, if none given the same will be 1 by X
		order:		F or C for Fortran or C, default is C
	OUTPUT
		data as a numpy array
	DEPENDENCIES
		numpy	
   POSSIBLE dtypes:
      i          integer
      uint       unsigned integer
      f          float
      c          comples float
      S (or a)   string
      U          unicode
      
      1          8 bit
      4          32 bit
      8          64 bit
      16         128 bit

      >          big-endian
      <          little-endian
	"""
	from numpy import array, memmap
	if shape:
		return array(memmap(file_name, mode = 'r', dtype = dtype, order = order, shape = shape, offset = offset)) * mult
	else:
		return array(memmap(file_name, mode = 'r', dtype = dtype, order = order, offset = offset)) * mult


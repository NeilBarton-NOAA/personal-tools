################################################
def unixtime2dtg(dtg, dtg_text = '%Y-%m-%d %HZ'):
    from time import strftime, gmtime
    return strftime(dtg_text, gmtime(dtg))

################################################
def dtg2unixtime(dtg, string = '%Y%m%d%H'):
    from calendar import timegm
    from time import strptime
    return timegm(strptime(dtg, string))

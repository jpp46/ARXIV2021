module DTW

using PyCall

export dtw

function __init__()
    py"""
    from dtw import *

    def my_dtw(a, b):
        alignment = dtw(a, b, keep_internals=True)
        return alignment.normalizedDistance
    """
end

dtw(a, b) = py"my_dtw"(a, b)

end
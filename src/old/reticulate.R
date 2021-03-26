library(reticulate)
use_virtualenv("python3")



main <- import_main()

builtins <- import_builtins()
builtins$print('foo')

os <- import("os")
os$listdir(".")

py_run_string("x = 10")
py$x

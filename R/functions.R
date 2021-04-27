library(RPostgreSQL)

get_db_conn <-
  function(db_name = "sdad",
           db_host = "postgis1",
           db_port = "5432",
           db_user = Sys.getenv("db_usr"),
           db_pass = Sys.getenv("db_pwd")) {
    RPostgreSQL::dbConnect(
      drv = RPostgreSQL::PostgreSQL(),
      dbname = db_name,
      host = db_host,
      port = db_port,
      user = db_user,
      password = db_pass
    )
  }

extract_rmd_yml <- function(file_path) {
  #browser()
  if (file.exists(file_path)) {
    yml_txt <- readr::read_lines(file_path)
    delims <- stringr::str_locate(yml_txt, "^---$")
    rws <- which(!is.na(delims[, 1]))
    if (length(rws) == 2) {
      temp <- tempfile()
      on.exit(unlink(temp))
      writeLines(yml_txt[rws[1]:rws[2]], con = temp)
      return(yaml::read_yaml(temp))
    } else {
      return("No yaml detected")
    }
  } else {
    return(paste("file", file_path, "doesn't exist"))
  }
}

get_menu_title <- function(file_path) {
  rmd_yml <- extract_rmd_yml(file_path)
  menu_title <- rmd_yml$menu_title
  menu_section <- stringr::str_match(file_path, "dp_ds([0-9][0-9])")
  if (!is.null(menu_title)) {
    data.frame(menu_section = menu_section[,2], menu_title = menu_title)
  }
}

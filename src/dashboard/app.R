library(shiny)
library(reactable)
library(RPostgreSQL)
library(data.table)
library(here)
library(stringr)
library(shinymanager)

# get_db_conn <-
#   function(db_name = "sdad",
#            db_host = "localhost",
#            db_port = "5434",
#            db_user = Sys.getenv("db_usr"),
#            db_pass = Sys.getenv("db_pwd")) {
#     RPostgreSQL::dbConnect(
#       drv = RPostgreSQL::PostgreSQL(),
#       dbname = db_name,
#       host = db_host,
#       port = db_port,
#       user = db_user,
#       password = db_pass
#     )
#   }
# con <- get_db_conn()
#
# df <- dbGetQuery(con, "SELECT * FROM corelogic_usda.variable_combinations", row.names = FALSE)
# dbDisconnect(con)
# saveRDS(df, "varcombos.RDS")

# define some credentials
credentials <- data.frame(
  user = c("USDA", "shinymanager"), # mandatory
  password = c("Broadband", "12345"), # mandatory
  start = c("2019-04-15"), # optinal (all others)
  expire = c(NA, "2021-12-31"),
  admin = c(FALSE, TRUE),
  comment = "Simple and secure authentification mechanism
  for single ‘Shiny’ applications.",
  stringsAsFactors = FALSE
)

dt <-setDT(readRDS("corelogic_have_all_vars_fnl.RDS"))

state_codes <- setDT(tigris::states()) %>%
  .[, c("GEOID", "NAME")] %>%
  setnames(., c("geoid_st", "name")) %>%
  setorder(., name)

state_codes_chr <- as.character(state_codes$geoid_st)
names(state_codes_chr) <- state_codes$name

cnty_files <- unlist(list.files("www/county_data/"))
cnty_codes <- str_extract(cnty_files, "[0-9]{5}")
links <- paste0("<a href='./county_data/", cnty_files, "'>", cnty_files, "</a>")
cnty_files_dt <- data.table(file_link = links, geoid_cnty = cnty_codes)

m_dt <- merge(dt, cnty_files_dt, by = "geoid_cnty", all.x = T)

# deed_codes <- read.csv("deed_codes.csv")
tax_rol_cols <- read.csv("tax_role_columns.csv")
tax_rol_codes <- read.csv("tax_roll_codes.csv")

ui <- fluidPage(

  h2("Arms-Length Sales of Single Family Residence / Townhouse"),
  h3("As Recorded in Corelogic Historical Tax Roles* and Satisfying the Following Conditions"),
  # hr(),
  # h4("Required Variable Categories and Applicable Column Conditions"),
  div(strong("Type of Property:"), HTML("<i>property_indicator</i>"), "EQUALS '10' (Single Family Residence / Townhouse)"),
  div(strong("Type of Transaction:"), HTML("<i>transaction_type</i>"), "DOES NOT EQUAL '9' (Nominal - Non/Arms Length Sale)"),
  div(strong("Size of Residence:"), "EITHER", HTML("<i>building_square_feet</i>"),"IS NOT NULL OR", HTML("<i>living_square_feet</i>"), "IS NOT NULL"),
  div(strong("Size of Property:"), "EITHER", HTML("<i>acres</i>"),"IS NOT NULL OR", HTML("<i>land_square_footage</i>"), "IS NOT NULL"),
  div(strong("Age of Property:"), "EITHER", HTML("<i>year_built</i>"),"IS NOT NULL OR", HTML("<i>effective_year_built</i>"), "IS NOT NULL"),
  div(strong("Number of Bathrooms:"), "EITHER", HTML("<i>full_baths</i>"), "IS NOT NULL OR", HTML("<i>1qtr_baths</i>"), "IS NOT NULL OR", HTML("<i>3qtr_baths</i>"), "IS NOT NULL OR", HTML("<i>half_baths</i>"), "IS NOT NULL OR",  HTML("<i>total_baths</i>"), "IS NOT NULL"),
  div(strong("Date of Sale:"), "sale_date IS NOT NULL"),
  div(strong("Price of Sale:"), "sale_price IS NOT NULL"),
  p(" "),
  p("* Corelogic Historical Tax Roles dataset was Joined to Corelogic Bulk Deeds dataset to include Primary Category Code on sales prior to 2018"),
  hr(),

  selectInput(inputId = "state",
              label = "Choose a state:",
              # choices = list("Virginia" = "51",
              #                "Iowa" = "19"),
              choices = state_codes_chr,
              selected = "Virginia"),

  checkboxInput(inputId = "cat_req", label = "Primary Category Code Required"),
  hr(),

  h4("Count of sales per county satisfying all conditions (in parentheses is total count of sales that are Single Family Residence / Townhouse that are not Non/Arms Length Sales"),

  tabsetPanel(type = "tabs",
              tabPanel("Counts",
                       reactableOutput("table")
                      ),
              # tabPanel("Deed Codes",
              #          div(
              #            reactableOutput("codes")
              #          )),
              tabPanel("Tax Roll Columns",
                       div(
                         reactableOutput("tax_cols")
                       )),
              tabPanel("Tax Roll Codes",
                       div(
                         reactableOutput("tax_codes")
                       ))
  )


)

# Wrap your UI with secure_app
ui <- secure_app(ui)

server <- function(input, output, session) {

  # call the server part
  # check_credentials returns a function to authenticate users
  res_auth <- secure_server(
    check_credentials = check_credentials(credentials)
  )

  output$auth_output <- renderPrint({
    reactiveValuesToList(res_auth)
  })


  output$table <- renderReactable({
    #browser()
    term <- paste0("^", input$state)
    dto <- m_dt[geoid_cnty %like% term & pri_cat_code_req == input$cat_req]

    # term <- paste0("^", state, "*")
    # dto <- dt[geoid_cnty %like% term & pri_cat_code_req == cat_req]

    r <- reactable(
      dto,
      filterable = FALSE,
      searchable = FALSE,
      rownames = FALSE,
      #showPageSizeOptions = TRUE,
      #pageSizeOptions = c(10, 50, 100),
      #defaultPageSize = 10,
      pagination = FALSE,
      height = 800,
      #defaultSorted = list(Species = "asc", Petal.Length = "desc"),
      defaultColDef = colDef(
        # cell = function(value) format(value, nsmall = 0),
        style = "font-size: 11px;",
        align = "left",
        minWidth = 70,
        headerStyle = list(background = "#f7f7f8", fontSize = "12px"),
        sortNALast = TRUE
      ),
      columns = list(
        file_link = colDef(html = TRUE)
      ),

      # columns = list(
      #   vars = colDef(name = "Variable Combination",
      #                 style = "white-space: nowrap; min-width: 300px; font-size: 12px;",
      #                 headerStyle = list(minWidth = "300px", fontSize = "12px")
      #               ),
      #   name = colDef(name = "County Name",
      #                 style = "white-space: nowrap; min-width: 120px; font-size: 12px;",
      #                 headerStyle = list(minWidth = "120px", fontSize = "12px")
      #   ),
      #   geoid = colDef(name = "FIPS"
      #   ),
      #   pct13 = colDef(format = colFormat(percent = TRUE, digits = 1)),
      #   pct14 = colDef(format = colFormat(percent = TRUE, digits = 1)),
      #   pct15 = colDef(format = colFormat(percent = TRUE, digits = 1)),
      #   pct16 = colDef(format = colFormat(percent = TRUE, digits = 1)),
      #   pct17 = colDef(format = colFormat(percent = TRUE, digits = 1))
      #   ),
      #   Price = colDef(aggregate = "max"),
      #   MPG.city = colDef(aggregate = "mean", format = colFormat(digits = 1)),
      #   DriveTrain = colDef(aggregate = "unique"),
      #   Man.trans.avail = colDef(aggregate = "frequency")
      #   # Type = colDef(header = function(value) {
      #   #   div(title = value, value, style="font-variant-caps: small-caps; transform: rotate(-60deg);")
      #   # })
      # ),
      bordered = TRUE,
      striped = TRUE,
      highlight = TRUE
      # ,
      # groupBy = "pri_cat_code_req"
    )
    # htmltools::save_html(r, "test2.html")
  })

  # output$codes <- renderReactable({
  #   reactable(
  #     deed_codes,
  #     filterable = FALSE,
  #     searchable = FALSE,
  #     rownames = FALSE,
  #     #showPageSizeOptions = TRUE,
  #     #pageSizeOptions = c(10, 50, 100),
  #     #defaultPageSize = 10,
  #     pagination = FALSE,
  #     height = 800,
  #     #defaultSorted = list(Species = "asc", Petal.Length = "desc"),
  #     defaultColDef = colDef(
  #       # cell = function(value) format(value, nsmall = 0),
  #       style = "font-size: 12px;",
  #       align = "left",
  #       minWidth = 70,
  #       headerStyle = list(background = "#f7f7f8", fontSize = "12px"),
  #       sortNALast = TRUE
  #     ),
  #     bordered = TRUE,
  #     striped = TRUE,
  #     highlight = TRUE,
  #     groupBy = "Field.Name"
  #   )
  # })

  output$tax_cols <- renderReactable({
    reactable(
      tax_rol_cols,
      filterable = FALSE,
      searchable = FALSE,
      rownames = FALSE,
      #showPageSizeOptions = TRUE,
      #pageSizeOptions = c(10, 50, 100),
      #defaultPageSize = 10,
      pagination = FALSE,
      height = 800,
      #defaultSorted = list(Species = "asc", Petal.Length = "desc"),
      defaultColDef = colDef(
        # cell = function(value) format(value, nsmall = 0),
        style = "font-size: 10px;",
        align = "left",
        minWidth = 70,
        headerStyle = list(background = "#f7f7f8", fontSize = "12px"),
        sortNALast = TRUE
      ),
      bordered = TRUE,
      striped = TRUE,
      highlight = TRUE,
      groupBy = "CATEGORY"
    )
  })

  output$tax_codes <- renderReactable({
    reactable(
      tax_rol_codes,
      filterable = FALSE,
      searchable = FALSE,
      rownames = FALSE,
      #showPageSizeOptions = TRUE,
      #pageSizeOptions = c(10, 50, 100),
      #defaultPageSize = 10,
      pagination = FALSE,
      height = 800,
      #defaultSorted = list(Species = "asc", Petal.Length = "desc"),
      defaultColDef = colDef(
        # cell = function(value) format(value, nsmall = 0),
        style = "font-size: 10px;",
        align = "left",
        minWidth = 70,
        headerStyle = list(background = "#f7f7f8", fontSize = "12px"),
        sortNALast = TRUE
      ),
      bordered = TRUE,
      striped = TRUE,
      highlight = TRUE,
      groupBy = "CdTbl"
    )
  })
}

shinyApp(ui, server)

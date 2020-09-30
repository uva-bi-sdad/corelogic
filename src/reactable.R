library(shiny)
library(reactable)
library(RPostgreSQL)
library(data.table)

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

dt <-setDT(readRDS("varcombos.RDS"))

deed_codes <- read.csv("deed_codes.csv")

ui <- fluidPage(
  h2("Counts for Different Combinations of Variables in CoreLogic Deed Records"),

  selectInput(inputId = "state",
              label = "Choose a state:",
              choices = list("Virginia" = "51",
                             "Iowa" = "19"),
              selected = "Virginia"),

  tabsetPanel(type = "tabs",
              tabPanel("Counts",
                       div(
                         "SA = Sales Amount, SD = Sales Date, TT = Transaction Type, SC = Sales Code, C1 = Primary Deed Category Type,
    C2 = Secondary Deed Category Types, LA = Land Acreage, LS = Land Squre Footage, PI = Property Indicator, BD = Total Bedrooms, BA = Total Baths"
                       ),
                       hr(),
                       reactableOutput("table")
                      ),
              tabPanel("Deed Codes",
                       div(
                         reactableOutput("codes")
                       ))
  )


)

server <- function(input, output) {

  output$table <- renderReactable({
    #browser()
    term <- paste0("^", input$state, "*")
    dt <- dt[geoid %like% term]

    r <- reactable(
      dt,
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
        style = "font-size: 12px;",
        align = "left",
        minWidth = 70,
        headerStyle = list(background = "#f7f7f8", fontSize = "12px"),
        sortNALast = TRUE
      ),
      columns = list(
        vars = colDef(name = "Variable Combination",
                      style = "white-space: nowrap; min-width: 300px; font-size: 12px;",
                      headerStyle = list(minWidth = "300px", fontSize = "12px")
                    ),
        name = colDef(name = "County Name",
                      style = "white-space: nowrap; min-width: 120px; font-size: 12px;",
                      headerStyle = list(minWidth = "120px", fontSize = "12px")
        ),
        geoid = colDef(name = "FIPS"
        ),
        pct13 = colDef(format = colFormat(percent = TRUE, digits = 1)),
        pct14 = colDef(format = colFormat(percent = TRUE, digits = 1)),
        pct15 = colDef(format = colFormat(percent = TRUE, digits = 1)),
        pct16 = colDef(format = colFormat(percent = TRUE, digits = 1)),
        pct17 = colDef(format = colFormat(percent = TRUE, digits = 1))
        ),
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
      highlight = TRUE,
      groupBy = "vars"
    )
    # htmltools::save_html(r, "test2.html")
  })

  output$codes <- renderReactable({
    reactable(
      deed_codes,
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
        style = "font-size: 12px;",
        align = "left",
        minWidth = 70,
        headerStyle = list(background = "#f7f7f8", fontSize = "12px"),
        sortNALast = TRUE
      ),
      bordered = TRUE,
      striped = TRUE,
      highlight = TRUE,
      groupBy = "Field.Name"
    )
  })
}

shinyApp(ui, server)

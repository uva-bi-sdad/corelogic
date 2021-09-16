library(shiny)
library(reactable)
library(RPostgreSQL)
library(data.table)
library(here)
library(stringr)
library(shinymanager)


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

# dt <-setDT(readRDS("corelogic_have_all_vars_fnl.RDS"))

# Load arms length sales with percent all vars file
# dt <- setDT(readRDS("src/dashboard/cl_arms_length_sales_pct_all_vars.RDS"))
dt <- setDT(readRDS("cl_arms_length_sales_pct_all-7_30aug21.Rds"))

# state_codes <- setDT(tigris::states()) %>%
#   .[, c("GEOID", "NAME")] %>%
#   setnames(., c("geoid_st", "name")) %>%
#   setorder(., name)

# Create Named List of State Codes
# state_codes <- readRDS("src/dashboard/state_codes.RDS")
state_codes <- readRDS("state_codes.RDS")
state_codes_chr <- as.character(state_codes$geoid_st)
names(state_codes_chr) <- state_codes$name

# Create table of county data file links
# cnty_files <- unlist(list.files("src/dashboard/www/county_data/"))
cnty_files <- unlist(list.files("./www/"))
cnty_codes <- str_extract(cnty_files, "[0-9]{5}")
links <- paste0("<a href='", cnty_files, "'>", cnty_files, "</a>")
cnty_files_dt <- data.table(file_link = links, geoid_cnty = cnty_codes)

# Merge arms length sales with links
m_dt <- merge(dt, cnty_files_dt, by = "geoid_cnty", all.x = T)


# tax_rol_cols <- read.csv("src/dashboard/tax_role_columns.csv")
tax_rol_cols <- read.csv("shiny_app_dict_19aug21.csv")
# tax_rol_codes <- read.csv("src/dashboard/tax_roll_codes.csv")
tax_rol_codes <- read.csv("shiny_app_codebook_20aug21.csv")

# Load Program Eligible Properties
# el <- setDT(readRDS("src/dashboard/cl_program_eligible_properties.RDS"))
# el <- setDT(readRDS("cl_program_eligible_properties.RDS"))


# RENDER APP
ui <- fluidPage(

  h2("Arms-Length Sales of Single Family Residence / Townhouse"),
  h3("As Recorded in Corelogic Historical Tax Roles and Satisfying the Following Conditions"),
  # hr(),
  # h4("Required Variable Categories and Applicable Column Conditions"),
  #h3("Arms-Length Transactions"),
 
  #h3("Required Characteristics"),
  h4("Location of Property"),
  div('Property location is described by a FIPS county code, a standard Census Geographic Entity ID, a full property address (including house number and suffix, street name, direction and type, unit number, city, state, zip code and county, and parcel-level centroid geographical coordinates. See the data dictionary for details.'),
  h4('Type of Property'),
  div('The data set includes only single-family type of properties. This is equivalent to setting the "Property Indicator" equal to 10. Single family housing is comprised of single-family residences, townhouses, apartments, condo, coops, flats, multi-plexes, row, mobile, manufactured homes etc. See "Building Use Code" ("BLDG") for details.'),
  h4("Date of Sale"),
  div('This is the date when the sale contract was signed in "YYYYMMDD" format.'),
  h4("Price of Sale"),
  div('The data set includes only the latest sale amount in dollars.'),
  h4("Type of Transaction"),
  div("This data set represents transactions that are referred to as \"arms-length\". This is what we might call a \"typical\" transaction between two parties, not a special transaction between parties, such as a sale to a relative for a reduced amount. For this data, there are many transaction types, but type '9' is specified for transaction that are \"non-arms-length\", so the requirement that is used here is to not include transactions that are coded '9'."),
  h4("Size of Residence"),
  div('Size of residence is represented by either a building size in sq. ft or a size of the living area in sq. ft.'),
  h4("Size of Property"),
  div('Size of residence is represented by either a building size in sq. ft or a size of the living area in sq. ft.'),
  h4("Age of Property"),
  div('The construction year the original building or the year when the building was first assessed with current components is used to calculate the age of the property.'),
  h4("Number of Bedrooms"),
  div('This is the total number of bedrooms in all buildings.'),
  h4("Number of Bathrooms"),
  div('The “total_baths” variable provided was not always calculated, even when other bath columns had values, therefore we used the Fannie Mae and Freddie Mac Uniform Appraisal Dataset Specification to calculate “baths_appraised”. 3/4 baths count as full baths, 1/4 baths are dropped, half bath is .1 of full bath, so 1 x full bath & 1 x 3/4 bath & 1 x half bath = 2.1 baths (2 full baths, 1 half bath).'),

  # div(strong("Type of Property:"), HTML("<i>property_indicator</i>"), "EQUALS '10' (Single Family Residence / Townhouse)"),
  # div(strong("Type of Transaction:"), HTML("<i>transaction_type</i>"), "DOES NOT EQUAL '9' (Nominal - Non/Arms Length Sale)"),
  # div(strong("Size of Residence:"), "EITHER", HTML("<i>building_square_feet</i>"),"IS NOT NULL OR", HTML("<i>living_square_feet</i>"), "IS NOT NULL"),
  # div(strong("Size of Property:"), "EITHER", HTML("<i>acres</i>"),"IS NOT NULL OR", HTML("<i>land_square_footage</i>"), "IS NOT NULL"),
  # div(strong("Age of Property:"), "EITHER", HTML("<i>year_built</i>"),"IS NOT NULL OR", HTML("<i>effective_year_built</i>"), "IS NOT NULL"),
  # div(strong("Number of Bathrooms:"), "EITHER", HTML("<i>full_baths</i>"), "IS NOT NULL OR", HTML("<i>1qtr_baths</i>"), "IS NOT NULL OR", HTML("<i>3qtr_baths</i>"), "IS NOT NULL OR", HTML("<i>half_baths</i>"), "IS NOT NULL OR",  HTML("<i>total_baths</i>"), "IS NOT NULL"),
  # div(strong("Date of Sale:"), "sale_date IS NOT NULL"),
  # div(strong("Price of Sale:"), "sale_price IS NOT NULL"),
  hr(),

  selectInput(inputId = "state",
              label = "Choose a state:",
              # choices = list("Virginia" = "51",
              #                "Iowa" = "19"),
              choices = state_codes_chr,
              selected = "Virginia"),

  # checkboxInput(inputId = "cat_req", label = "Primary Category Code Required"),
  hr(),

  tabsetPanel(type = "tabs",
              tabPanel("Counts",
                       h4("Count of sales per county that are arms-length and SFR (in parentheses is percent of count of sales that satisfy the required criteria.)"),
                       div("The first entry is the total number of sales that are arms-length and a single-family residence. In parentheses is the percentage of sales that satisfy all ten of the criteria listed above.
The second entry is the number of sales that satisfy any of the 9 out of 10 criteria (in paratheses in percent of all sales that are arms-length sales and a SFR). The third and fourth entries are count of sales which satisfy any of the 8 out of 10 and 7 out of 10 criteria correspondingly. 
"),
                       reactableOutput("table")
                      ),
              # tabPanel("Deed Codes",
              #          div(
              #            reactableOutput("codes")
              #          )),
              tabPanel("Data Dictionary",
                       div(
                         reactableOutput("tax_cols")
                       )),
              tabPanel("Data Values",
                       div(
                         reactableOutput("tax_codes")
                       )),
              tabPanel("Program Eligible Properties",
                       div(
                         h4("Here you can download the data file identifying all properties eligible for the BIP, CC, RC, TCF, and TCI USDA programs"),
                         h4("This file can be joined to Arms Length sales data on the geoid_cnty and p_id_iris_frmtd columns."),
                         HTML("<a href = './cl_program_eligible_properties.zip'>program_eligible_properties</a>")
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
    #dto <- m_dt[geoid_cnty %like% term & pri_cat_code_req == input$cat_req]

    # term <- paste0("^", state, "*")
    # dto <- dt[geoid_cnty %like% term & pri_cat_code_req == cat_req]
    dto <- m_dt[geoid_cnty %like% term]

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
      #groupBy = "CATEGORY"
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
      groupBy = "Table"
    )
  })
}

shinyApp(ui, server)

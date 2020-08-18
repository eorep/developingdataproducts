#
# This is the user-interface definition of a Shiny web application. 

library(shiny)
library(shinythemes)
 
# Define UI for application that draws a histogram
shinyUI(fluidPage(
    theme = shinytheme("simplex"),
    
    tags$head(
        tags$style(HTML("
            h1 {
            font-weight: 500;
            line-height: 1.1;
            color: #d13232;
            };
            
            #tableInfo {
              border-collapse: collapse;
              width: 100%;
            }
            
            #tableInfo td, #tableInfo th {
              border: 1px solid #ddd;
              padding: 6px;
            }
            
            #tableInfo tr:nth-child(even){background-color: #f2f2f2;}
            
            #tableInfo th {
              background-color: #d13232;
              color: white;
            }
      
        "))
        ),

    # Application title
  ##  titlePanel("Credit Score application demo"),

    # Show a plot of the generated distribution
    mainPanel(
        navlistPanel( id="navPanelMain",
            tabPanel(title="Instructions", value = "panelInstructions",
                     withTags( 
                         div(
                             h1("Credit Score application demo"),
                             p("The objective of this application is to demostrate the use of Machine learning to help financial analysts evaluate the worthiness of credit applicants and to show the flexibility of Shiny Apps to create this demo."),
                             h3("Procedure"),
                             ol( li("Click on 'Input form' section"), 
                                 li("Fill out the form*"),
                                 li("Click on 'Click to evaluate'"),
                                 li("The application will indicate if the applicat is credible or not to receive the credit and the degree of confidence of the result in the panel 'Evaluation results' ") ),
                             p("The 'Model Details' panel contains information about the statistical model used to create this application."),
                             p("The Reference panel includes information about the dataset used and other references."),

                             h3("*Form details"),
                             p("The input form includes the following fields:"),
                             table( id="tableInfo", 
                                   tr( th("Field"), th("Description")),
                                   tr( td("Requested credit amount"), td("Amount of the credit requested by the applicant.") ),
                                   tr( td("Gender"), td("Indicate the gender of the applicant. ") ),
                                   tr( td("Education"), td("Choose the highest education level of the applicant.") ),
                                   tr( td("Marital Status"), td("Indicate the marital status of the applicant.") ),
                                   tr( td("Age"), td("Indicate the age of the applicant.") ),
                                   tr( td("General Payments status "), td("Select the average status of the applicant's payment of credit for the past six months.  ") ),
                                   tr( td("Range bill statements"), td("Indicate the range of bill statements from applicant's last six months.") ),
                                   tr( td("Range paid bills"), td("Indicate the range of bills paid from last six months from applicant.") )
                                  )
                         )
                     )
                     ),
            tabPanel(title = "Input form", value = "panelInput",
                     
                     wellPanel(
                         p("Please fill out this application form:"),
                     sliderInput("icredit",
                                 "Requested credit amount:",
                                 min = 10000,
                                 max = 500000,
                                 step = 1000,
                                 value = 15000),
                     radioButtons("igender", 
                                  "Gender", 
                                  c("Male" = "male",
                                    "Female" = "female")),
                     selectInput("ieducation",
                                 "Education",
                                 c("Graduate School" = "graduate school",
                                   "University" = "university",
                                   "High School" = "high school",
                                   "Others" = "others")),
                     radioButtons("imaritalstatus", 
                                  "Marital Status", 
                                  c("Married" = "married",
                                    "Single" = "single",
                                    "Other" = "others")),
                     sliderInput("iage",
                                 "Age:",
                                 min = 21,
                                 max = 79,
                                 step = 1,
                                 value = 34),
                     selectInput("ipaymentstatus",
                                 "General Payments status",
                                 c("Pay duly" = "-1",
                                   "Payment delay for one month" = "0",
                                   "Payment delay for two months" = "1",
                                   "Payment delay for three months" = "2",
                                   "Payment delay for four months" = "3",
                                   "Payment delay for five months" = "4",
                                   "Payment delay for six months" = "5",
                                   "Payment delay for seven months" = "6",
                                   "Payment delay for eight months" = "7",
                                   "Payment delay for nine months or more" = "8")),
                     sliderInput("ibillrange",
                                 "Range bill statements:",
                                 min = 0,
                                 max = 60000,
                                 step = 100,
                                 value = c(0, 5000)),
                     sliderInput("ipaymentrange",
                                 "Range paid bills:",
                                 min = 0,
                                 max = 10000,
                                 step = 100,
                                 value = c(0, 2000)),
                     actionButton("evaluate", "Click to Evaluate", class = "btn-primary")
                     )
                     ),
            tabPanel(title="Evaluation results", value = "panelResults",
                     tags$h1("Evaluation results:"),
                     tags$p("Based on the data entered:"),
                     tableOutput("table1"),
                     tags$p("and some random information generated using those values, "),
                     h4(htmlOutput("result"))
                     ),
            tabPanel(title="Model details", value = "panelModel",
                     withTags(
                         div(
                             h1("Statistical model"),
                             p("To train this classification problem I choose the following models: "),
                             ul( li("Generalized Liner Model"), 
                                 li("Random Forest"),
                                 li("Neural Network")),
                             p(paste("The results showed that the three models resulted in accuray between 81% and 82%."),
                               "Also considering that GLM model was the fastest, I decided to use this one for prediction."),
                             p("These are the top variables that affects the GLM model:"),
                             plotOutput("plotTopVariables")
                         )
                     )
            ),
            tabPanel(title="References", value = "panelReference",
                     withTags(
                         div(
                             h1("References"),
                             ul( li(tagList(b("Data source:"), "Yeh, I. C., & Lien, C. H. (2009).",
                                 "The comparisons of data mining techniques for the predictive accuracy of probability",
                                 "of default of credit card clients. Expert Systems with Applications, 36(2), 2473-2480.",
                                 a("Link.", href="http://archive.ics.uci.edu/ml/datasets/default+of+credit+card+clients")) ), 
                                     li("Libraries used: caret, recipes, ggplot2, dplyr, readxl, parallel, doParallel, shiny and shinythemes"),
                                ),
                             p("Created by: Elmer Ore.")
                            
                         )
                     )
            )
        )
        
    )
)
)

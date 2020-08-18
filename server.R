#
# This is the server logic of a Shiny web application. 

library(shiny)
library(caret)
library(recipes)
library(dplyr)

load("data_format.rda")
load(file = "trained_recipe.rda")
load(file = "GLMClassification.rda")
 
# Define server logic required to 
shinyServer(function(input, output, session) {

    credit <- eventReactive(input$evaluate, { as.numeric(input$icredit) })
    gender <- eventReactive(input$evaluate, { input$igender})
    education <- eventReactive(input$evaluate, { input$ieducation })
    maritalstatus <- eventReactive(input$evaluate, { input$imaritalstatus })
    age <- eventReactive(input$evaluate, { input$iage })
    paymentstatusint <- eventReactive(input$evaluate, { input$ipaymentstatus })
    paymentstatus <- eventReactive(input$evaluate, { 
        switch(input$ipaymentstatus, 
               "-1" = "Pay duly", 
               "0" = "Payment delay for one month", 
               "1" = "Payment delay for two months",
               "2" = "Payment delay for three months",
               "3" = "Payment delay for four months",
               "4" = "Payment delay for five months",
               "5" = "Payment delay for six months",
               "6" = "Payment delay for seven months",
               "7" = "Payment delay for eight months",
               "8" = "Payment delay for nine months or more")
        })
    billleft <- eventReactive(input$evaluate, { input$ibillrange[1] })
    billright <- eventReactive(input$evaluate, { input$ibillrange[2] })
    payleft <- eventReactive(input$evaluate, { input$ipaymentrange[1] })
    payright <- eventReactive(input$evaluate, { input$ipaymentrange[2] })
    billrange <- eventReactive(input$evaluate, { 
        input$ibillrange[1] 
        })
    paymentrange <- eventReactive(input$evaluate, { 
        input$ipaymentrange[1] 
        })
    
    
    observeEvent(input$evaluate, {
        output$table1 <- renderTable(
            data.frame("Credit" = credit(), 
                       "Gender" = gender(),
                       "Education" = education(),
                       "Marital Status" = maritalstatus(),
                       "Age" = age(), 
                       "Payment status" = paymentstatus(),
                       "Bill range" = paste(billleft(), "-", billright()),
                       "Pay range" = paste(payleft(), "-", payright()))
        )
        
        set.seed(1234)
        bill <- sample(billleft():billright(), 6, replace = TRUE)
        set.seed(1241)
        paid <- sample(payleft():payright(), 6, replace = TRUE)
        set.seed(9888)
        status <- sample(-1:1, 6, replace=TRUE)
        
        if (paymentstatusint() == "-1") {
            status <- status + as.integer(paymentstatusint()) + 1
        }
        else if (paymentstatusint() == "8") {
            status <- status + as.integer(paymentstatusint()) - 1
        }
        else {
            status <- status + as.integer(paymentstatusint())    
        }
        # pay 5 and pay 6 have one level less  (1)
        status[5] <- ifelse (status[5]==1, 0, status[5])
        status[6] <- ifelse (status[6]==1, 0, status[6])
        status <- as.factor(status)

        data_eval[1, "LIMIT_BAL"] <- credit()
        data_eval[1, "SEX"] <- gender()
        data_eval[1, "EDUCATION"] <- education()
        data_eval[1, "MARRIAGE"] <- maritalstatus()
        data_eval[1, "AGE"] <- age()
        data_eval[1, "PAY_1"] <- status[1]
        data_eval[1, "PAY_2"] <- status[2]
        data_eval[1, "PAY_3"] <- status[3]
        data_eval[1, "PAY_4"] <- status[4]
        data_eval[1, "PAY_5"] <- status[5]
        data_eval[1, "PAY_6"] <- status[6]
        data_eval[1, "BILL_AMT1"] <- bill[1]
        data_eval[1, "BILL_AMT2"] <- bill[2]
        data_eval[1, "BILL_AMT3"] <- bill[3]
        data_eval[1, "BILL_AMT4"] <- bill[4]
        data_eval[1, "BILL_AMT5"] <- bill[5]
        data_eval[1, "BILL_AMT6"] <- bill[6]
        data_eval[1, "PAY_AMT1"] <- paid[1]
        data_eval[1, "PAY_AMT2"] <- paid[2]
        data_eval[1, "PAY_AMT3"] <- paid[3]
        data_eval[1, "PAY_AMT4"] <- paid[4]
        data_eval[1, "PAY_AMT5"] <- paid[5]
        data_eval[1, "PAY_AMT6"] <- paid[6]
        
        data_trained <- bake(trained_recipe, new_data = data_eval)
        predictGLM <- predict(fitGLM, newdata = data_trained)
        predictGLMprob <- predict(fitGLM, newdata = data_trained, type="prob")

        predictGLMprob <- ifelse(predictGLM=="credible", predictGLMprob[1,1], predictGLMprob[1,2])
        predictGLMprob <- paste0(as.character(round(predictGLMprob*100,2)), "%")
        color <- ifelse(predictGLM=="credible", "'color:blue'", "'color:red'")
        
        output$result <- renderUI(HTML(paste("<p style=", color, ">", 
                                             "the system found the client <b>",
                                            as.character(predictGLM),
                                            "</b>with probability<b>",
                                            predictGLMprob, "</b></p>")))
        
        updateNavlistPanel(session = session, inputId =  "navPanelMain", selected = "panelResults" )
        
    })
    
    varImportance <- varImp(fitGLM, scale=FALSE)
    output$plotTopVariables <- renderPlot({
        ggplot(varImportance, top=12) +
            ggtitle("Top variables that affect the approval process")
    })

})
 
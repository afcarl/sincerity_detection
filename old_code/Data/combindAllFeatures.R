setwd("~/Documents/CS224s/Analysis/Data")
praat_dat <- read.table('praat_with_header.csv', sep = ';', header = TRUE, row.names = NULL)
lab_dat <- read.table('speeddateoutcomes.csv', sep = ',', header = TRUE, row.names = NULL, na.strings = c('NA', '.', ' .', '. ', ' . ', ' '))
liwc_dat <- read.table('final_liwc_feats.csv', sep = ',', header = FALSE) #No header in this file
lex_dat <- read.table('final_lex_feats.csv', sep = ',', header = FALSE)

#Add header names to liwc_dat and lex_dat
old_all <- read.table('../all_new_features.csv', sep = ';', header = TRUE) 
liwc_names <- colnames(old_all)[472:535]
colnames(liwc_dat) = c(liwc_names, 'speak1', 'speak2', 'speak1bool')

lex_names <- colnames(old_all)[410:436]
colnames(lex_dat) <- c(lex_names, 'speak1', 'speak2', 'speak1bool')
remove(old_all)

#Remove 'male' and 'female' from the speaker variables
lex_dat$speak1 = as.numeric(substr(lex_dat$speak1, start = 5, stop = 7))
lex_dat$speak2 = as.numeric(substr(lex_dat$speak2, start = 7, stop = 9)) 

#Remove redundant columns from liwc
rem_rows = c()
check_redundant = c() #Vector of rows with redundant male, female, bool, but with diff. feature vals
n = nrow(liwc_dat)
for(i in 1:n){ 
  m = liwc_dat$speak1[i]
  f = liwc_dat$speak2[i]
  gen = liwc_dat$speak1bool[i]
  #Group of redundant_rows
  same_rows = which(liwc_dat$speak1 == m & liwc_dat$speak2 == f & liwc_dat$speak1bool == gen)
  if(length(same_rows) > 1){
    rows_to_remove = same_rows[1]
    if(gen) rows_to_remove = same_rows[2]
    
    #Old Code to Find Errors -- Rows w/ same male, female, malebool but diff vals
    if(FALSE){
      tester = unique(liwc_dat[same_rows,1:64])  
      if(nrow(tester) > 1){
        check_redundant = c(check_redundant, same_rows)
      }
    }
    
  }
  if(!(rows_to_remove %in% rem_rows)){
    rem_rows = c(rem_rows, rows_to_remove)
  }
}
liwc_dat = liwc_dat[-rem_rows,]


rem_rows_lex = c()
check_redundant = c() #Vector of rows with redundant male, female, bool, but with diff. feature vals
n = nrow(lex_dat)
for(i in 1:n){ 
  m = lex_dat$speak1[i]
  f = lex_dat$speak2[i]
  gen = lex_dat$speak1bool[i]
  #Group of redundant_rows
  same_rows = which(lex_dat$speak1 == m & lex_dat$speak2 == f & lex_dat$speak1bool == gen)
  if(length(same_rows) > 1){
    #Old Code to Find Errors
    if(FALSE){
      unique_from_same_rows = unique(lex_dat[same_rows,1:27])
      if(nrow(unique_from_same_rows) > 1){
        check_redundant = c(check_redundant, same_rows)
      }
    }
    row_to_remove = same_rows[1]
    if(gen) row_to_remove = same_rows[2]
  }
  if(!(row_to_remove %in% rem_rows_lex)){
    rem_rows_lex = c(rem_rows_lex, row_to_remove)
  }
}
lex_dat = lex_dat[-rem_rows_lex,]

#Merged Set of LIWC and Raw Lexical Features
liwc_lex_dat = cbind(liwc_dat[, 1:64], lex_dat)

#Now Combine LIWC and Lex With Praat
liwc_lex_reorder = rep(0, nrow(praat_dat))
for(i in 1:nrow(praat_dat)){
  speak = praat_dat$Speaker[i]
  oth = praat_dat$Other[i]
  if(speak < oth){  
    corres_row = which(liwc_lex_dat$speak1 == speak & liwc_lex_dat$speak2 == oth & liwc_lex_dat$speak1bool)  
  } else {
    corres_row = which(liwc_lex_dat$speak1 == oth & liwc_lex_dat$speak2 == speak & (!liwc_lex_dat$speak1bool))  
  }
  if(length(corres_row) == 1){
    liwc_lex_reorder[i] = corres_row
  } else {
    liwc_lex_reorder[i] = NA
  }
}

#Liwc_lex_data for combination
liwc_lex_comb = liwc_lex_dat[liwc_lex_reorder,]

#Testing
#cbind(praat_dat[, 1:2], liwc_lex_comb[, (ncol(liwc_lex_comb) - 2):ncol(liwc_lex_comb)])
praat_liwc_lex = cbind(praat_dat, liwc_lex_comb[, 1:(ncol(liwc_lex_comb) - 3)])

acc_dat <- read.table('final_acc_feats.csv', sep = ',', header = FALSE)
colnames(acc_dat) <- c('RateAcc', 'ContAcc', 'LaughAcc', 'FuncAcc', 'Male', 'Female', 'MaleBool')
acc_dat$MaleBool = (acc_dat$MaleBool == 'True')


#Get reordering of accommodation features to bind to praat_liwc_lex
acc_reorder = rep(0, nrow(praat_liwc_lex))
for(i in 1:nrow(praat_liwc_lex)){
  speak = praat_liwc_lex$Speaker[i]
  oth = praat_liwc_lex$Other[i]
  if(speak < oth){
    corres_row = which(acc_dat$Male == speak & acc_dat$Female == oth & acc_dat$MaleBool)  
  } else {
    corres_row = which(acc_dat$Male == oth & acc_dat$Female == speak & (!acc_dat$MaleBool))  
  }
  if(length(corres_row) == 1){
    acc_reorder[i] = corres_row
  } else {
    acc_reorder[i] = NA
  }
}
acc_comb = acc_dat[acc_reorder,]


#For testing
#cbind(praat_liwc_lex[, 1:2], acc_comb[, 5:7])

#Combine
praat_liwc_lex_acc = cbind(praat_liwc_lex, acc_comb[, 1:4]) #Combine

#Now combine with labels
lab_reorder = rep(0, nrow(praat_liwc_lex_acc))
for(i in 1:nrow(praat_liwc_lex_acc)){
  speak = praat_liwc_lex_acc$Speaker[i]
  oth = praat_liwc_lex_acc$Other[i]
  corres_row = which(lab_dat$selfid == speak & lab_dat$otherid == oth)
  if(length(corres_row) == 1){
    lab_reorder[i] = corres_row    
  } else {
    lab_reorder[i] = NA
  }
}
lab_comb = lab_dat[lab_reorder,]

#Complete Data Set
tot_dat <- cbind(lab_comb, praat_liwc_lex_acc[, 3:ncol(praat_liwc_lex_acc)])

write.table(tot_dat, 'final_features.csv', sep = ';', col.names = TRUE, row.names = FALSE)

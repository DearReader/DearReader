### Basic Set-up ###
#Please install and load the following packages, more info in README:
library(syuzhet)
library(stringr)
library(readr)

#Set working directory to wherever you have downloaded the repo:
#If you are on a windows machine you will need to escape the slashes: setwd("C:\\Downloads\\DearReader-main")
setwd("~/Downloads/DearReader-main")

#Locate the individual novels in the Text_Corpus folder:
input.dir<-"Test_Corpus"
files.v<-dir(input.dir, ".*txt")

#Cycle through each novel, performing the following tasks: 
for (i in 1: length(files.v)) {

#Print current novel title to consol to track progress of this script:
print(files.v[i])
  
#Read each novel in:  
text_v<-scan(paste(input.dir, files.v[i], sep="/"),
               what="character", sep="\n")

### Text Processing ###
#Tack the word "PARAGRAPH" onto the end of each paragraph so that after all the text is chunked together, it can be rebroken into paragraphs:
text_v<- gsub("(.*)", "\\1 PARAGRAPH", text_v)

#Convert plain single quotes to curly single quotes:
text_v<- gsub("(\\s|\\n|-|–|—|\'|^)'([a-zA-Z]|\'|_)", "\\1‘\\2", text_v)
text_v<- gsub("'(\\s|\\n|-|–|—|$|PARAGRAPH)", "’\\1", text_v)

#Convert double plain quotes to double curly quotes:
text_v<- gsub('(\\s|\\n|-|–|—|\'|^)"([a-zA-Z]|\'|_)', "\\1“\\2", text_v)
text_v<- gsub('"(\\s|\\n|-|–|—|”|$|PARAGRAPH)', "”\\1", text_v)

### Remove Embedded Correspondence ###
#Find paragraphs that contain the word "dear" in the first four words and no quotations:
para_dear<- text_v[intersect(grep("^(\\w*\\s){0,4}(?i)dear(?-i)",text_v),grep("“|”",text_v,invert=TRUE))]

#Paragraph must not include the word reader in the first six words "e.g.  dear gentle reader":
letters<-para_dear[grep("^(\\w*\\s){0,6}(?i)reader(?-i)",para_dear,invert=TRUE)]

#Remove possible correspondence beginning with 'dear' from salutation to next opening quote mark:
letters_bucket<- NULL
if (length(letters) > 0) {
  for (p in 1:length(letters)) {
    lettersnew<-match(letters[p], text_v)
    numbers<-c(0:20)
    range<-numbers+lettersnew
    v<-text_v[range]
    
    if (length(grep('“', v)) > 0) {
      hits<-grep('“', v, value=TRUE)
      first_hit<-hits[1]
      first_hit_position<-match(first_hit, text_v)-1
      letters_positions<-c(lettersnew:first_hit_position)
      letters_bucket<-c(letters_bucket, letters_positions)
    }
    else {
      print("too short")
      letters_bucket<-c(letters_bucket, range)
    }
  }
  letter_text<-text_v[letters_bucket]
  text_v<-text_v[-letters_bucket]
}

### Begin Removing Dialogue ###
#Remove two rounds of nested quotations at the paragraph level:
without_nested<- gsub('“[^“^”]*?”', "blank", text_v)
without_nested2<- gsub('“[^“^”]*?”', "blank", without_nested)

#Combine paragraphs in order to remove quotations that extend across multiple paragraphs:
combined_para<-paste(without_nested2, collapse = '')

#Remove from opening curly quote to closing curly quote OR from opening curly quote to six paragraphs forward:
#The reason for this is to prevent an overly greedy situation in which there is no true matching end quote, however, there is an unmatched end quote much further on in the document:
combined_para<- gsub("“((.*?PARAGRAPH.*?PARAGRAPH.*?PARAGRAPH.*?PARAGRAPH.*?PARAGRAPH.*?PARAGRAPH)|.*?”)", "COMBINED", combined_para, perl = TRUE)

#Put text back into original paragraphs:
separated_para<-unlist(strsplit(combined_para, split="PARAGRAPH"))

#Add curly double quote to end of each paragraph:
separated_para<- gsub("(.*)", "\\1”", separated_para)

#Remove any remaining quotes (gets rid of quotes that are missing closing quote):
separated_para2<- gsub('“[^“^”]*?”', "blank", separated_para)

### Detect Reader Address ###
#Tokenize sentences:
sentences <- tolower(get_sentences(separated_para2))

#Catch sentences with keywords and phrases:
patterns <- c("(\\n| |^)you(,| |\\.|:|;|\\!)", "your(,| |\\.|:|;|\\!)", "yourself", "yourselves", "reader", "our story", "my story", "my tale", "our tale", "our narrative", "my narrative")
my_reg <- paste(patterns, collapse = "|")
reader_address <- sentences[grep(my_reg, sentences)]

### Clean Output ###
#Remove rows that contain more than three single quote marks in the following format (to delete dialect that has snuck through):
single_quotes_patterns <-c(" (‘|’)[a-zA-Z]", "[a-zA-Z](‘|’) ", "\\.(‘|’)", ",(‘|’)", "bayou")
winnowed_reader_address<- NULL
if (length(reader_address) > 0) {
for (m in 1:length(reader_address)) {
  count<- str_count(reader_address[m], single_quotes_patterns)
  if (sum(count) < 3) {
    winnowed_reader_address<-c(winnowed_reader_address, reader_address[m])
  }
}
}

#Clean up quotation marks that remain:
winnowed_reader_address<- gsub('“', " ", winnowed_reader_address)
winnowed_reader_address<- gsub('”', " ", winnowed_reader_address)
winnowed_reader_address<- gsub('\\n', "", winnowed_reader_address)
winnowed_reader_address<- gsub('‘|’', "'", winnowed_reader_address)


### Create a CSV File of Address for Each Novel ###
#Put results from the current novel in a dataframe:
output.df<- as.data.frame(winnowed_reader_address)
names(output.df)[1] <- "sentences categorized as containing address"

#Individual CSV files written to the "Output" folder: 
write.csv(output.df, file=paste("Output/", gsub("txt", "csv", files.v[i])), fileEncoding = "UTF-16", row.names=FALSE)

}



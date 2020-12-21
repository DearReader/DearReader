# DearReader
## Intro
This repo contains code and corpus information for a larger project that uses regular expressions to detect moments of reader address in fiction. 

The goal of the project is to study the rhetorical usage of address across authors, periods, and genres using a combination of computational tools and close reading. The code and corpus are presented here to facilitate transparency. This project is ongoing and the repo will continue to evolve. 

Reader address is a wide ranging phenomenon that can be hard to pin down. Authors have used address to elicite sympathy, incite fear, and foster guilt. 

* she recovered, turned her face to the wall, and wept and sobbed like a child. Perhaps, mother, you can tell what she was thinking of! (Harriet Beecher Stowe, *Uncle Tom's Cabin*)

* At least some of the horror I took away at four in the morning you now have before you, waiting for you a little like it waited for me that night (Mark Danielewski, *House of Leaves*)

* if there be a dainty reader of this tale who scorns a lie, and who writes the story of his life upon his sleeve for all the world to read, let him uncurl his scornful lip and come down from the pedestal of superior morality (Charles Chesnutt, *The House Behind the Cedars*)

The code discussed below was designed to detect and extract such moments from a large fiction corpus. 

## Using this Repo

This repo contains the basic project code for detecting address (written in R), a 30 novel test corpus (.txt files), metadata for the entire corpus (.csv files), and a sample output file (.csv file): 

* Code
* Test Corpus
* Corpus Info
* Output

In order to run the code on the test corpus, you will need to first download and install [R](https://cran.r-project.org/mirrors.html). I also recommend downloading and installing [R Studio](https://rstudio.com/products/rstudio/download/), an environment for R. Both are free to download. 

You will also need to [install and load](https://www.datacamp.com/community/tutorials/r-packages-guide) the following packages in R: syuzhet, stringr, readr. If you are using R Studio, you can install packages through the [tools tab](http://web.cs.ucla.edu/~gulzar/rstudio/).

After downloading the repo, you should be able to run the code on the test corpus to produce a .csv file for each novel. This will allow you to see how the code works. You could also try adding your own .txt files to the corpus. 

Each .csv file will contain moments of reader address from the novel. For example, after running the code on the novel *Hagar's Daughter* (hagars_daughter.txt) from the Test Corpus folder, a .csv output file (hagars_daughter.csv) will be produced in the Output folder that contains the following sentences: 

sentences containing address |
-------------------------------------------------------------------------------------------------------------|
others will tell you first love is the only true passion; that it comes but once to every human being... |
no wonder you are incredulous. |
governor lowe then related the story of the past winter and the broken engagement, as known to our readers...|
then in graphic words that held the vast crowd spellbound, he told the story of ellis and st. clair enson, as our readers already know it...|


For an overview of how the code works, a discussion of significant flaws in the code, and for additional resources, please keep reading. 

## Methodologies

### Corpus

The test corpus includes 30 Anglophone novels published between 1817 and 1940. All of the novels are available on Project Gutenberg. The novels reflect different periods, genres, and styles. After hand-checking the results, I determined that 80% of address detected by the tool was correctly labeled as address. The tool performed very poorly on some novels (such as *Frankenstein* and *Little Women*) and well on most novels (including *Jane Eyre* and *Uncle Tom's Cabin*). It was not possible to determine recall. 

The full corpus includes 2000 Anglophone novels published between 1782 and 1923. These novels are part of the Chicago and Chadwyck Healey corpora, corpora often used in text analysis projects. Many of them are available on Gutenberg. Because of the amount of address detected, it was not possible to hand-check the results for precision or recall. 

I also examined a small corpus of 23 Anglophone African-American authored novels published between 1853 and 1917. These texts were collected from multiple online resources and were in part determined with the help of a [bibliography](https://bbip.ku.edu/1800-1930) composed by The University of Kansas.

Selection is always an interpretative process. Though large, the corpora used for this project are not exhaustive and cannot be guaranteed to reflect the general literary output of the nineteenth-century. Similarly the types of address I focus on are not exhaustive. 

### What is Address?

In the *Routledge Encyclopedia of Narrative Theory* Irene Kacandes defines address as “vocative formulations that identify the reader directly . . . ‘you’ and ‘dear reader’ are the most common [form].” The notion that certain words, such as “you” signal address is supported by the work of narratologists including Gerald Prince, Wolfgang Iser, and Robyn Warhol. This project focuses on sentences outside of dialogue in which readers are named (using specific words, such as “reader”) and sentences outside of dialogue in which the story itself is named as story (using specific words and phrases, such as “my story”).

There are virtually limitless combinations of words that can signal address. An author might, for example, refer to the reader as “my friend,” “the audience,” “my esteemed colleague,” etc.  

I focus on a specific subset of commonly used terms and phrases: 

* you
* your
* yourself
* yourselves 
* reader 
* readers
* our story 
* my story
* our tale
* my tale
* our narrative
* my narrative. 

These terms and phrases were included because of their prevalence in fiction and because they returned more true positives than false positives. Other terms where initially included, such as “dear friends” but were removed after I determined that they returned more false positives than true positives. 


### Removing Dialogue

The majority of the code for this project works to remove dialogue from narration. This is a difficult task because of the wide number of punctuation inconsensticies present in most ninteenth- and twentieth-century novels. 

Other approaches to separating narration and dialogue exist. Many (including mark-up based approaches) are too time intensive to employ on a large corpus. Some approaches use natural language processing and supervised learning to train a machine model that will automatically detect quotations. After testing one such approach (the tool qsample, created by Christian Scheible)
I found that a regex based approach performed better on the types of inconsistencies present in many nineteenth-century novels (such as a lack of a closing quotation mark when the end of a quote coincides with the end of a paragraph). 

The regex process is as follows: 

1. The text is first chunked into paragraphs and straight quotation marks are replaced with curly quotation marks using a regular expression. Curly quotations marks are preferable because they automatically signal whether a quote is a start or an end quote. 

	“You are a terrible reader,” **said Ruth** “you don't pay attention.

	“Well, it would be easier to pay attention if I wasn't reading a "boring" book 

	like this” **said Thomas. Reader, you know how kids can be.** 

2. Then quotations which do not contain embedded quotations are removed at the level of each paragraph. This is accomplished by looking for a start quote, end quote, and the characters in between, provided that neither a start quote nor an end quote exist in between. This will, at the paragraph level, remove an embedded quotation of any length, as well as a quotation of any length that does not contain an embedded quotation. 

	~~“You are a terrible reader,”~~ **said Ruth** “you don't pay attention.

	“Well, it would be easier to pay attention if I wasn't reading a 	~~"boring"~~ book 

	like this” **said Thomas. Reader, you know how kids can be.** 

3. Next, all paragraphs are combined in order to remove quotations that extend across paragraphs. 

	**said Ruth** “you don't pay attention. ~~“Well, it would be easier to pay attention if I wasn't reading a book 
		like this”~~ **said Thomas. Reader, you know how kids can be.** 

4. The remaining text is then chunked into the original paragraphs in order to process paragraphs that are missing an end quotation mark (either as a result of error or punctuation conventions). A closing curly quotation mark is added to the end of each paragraph. Any remaining content between opening and closing quote marks is deleted at the paragraph level. 

	**said Ruth** ~~“you don't pay attention.”~~

	**said Thomas. Reader, you know how kids can be.”**

5. The remaining narration is then split into sentences and searched for key words pertaining to address. 

	**Reader, you know how kids can be.**
		
The code also includes a section to help eliminate embedded correspondence (an extremeley common occurence in nineteenth-century novels). When the term "you" is used in a letter, it is typically one character speaking to another, not the narrator speaking to the reader. This phenomonen is one of the reasons the code performs so poorly on some novels (such as *Little Women*). The regex method for detecting correspondence is imperfect but does eliminate some commonly occuring forms of embedded correspondence (such as letters beginning with the salutation, Dear Recpient's Name).


## Additional Resources

For more detailed information about this project and its methodologies, please see: ["'This, Reader, Is No Fiction': Examining the Rhetorical Uses of Reader Address across the Nineteenth- and Twentieth-Century Novel"](https://digitalcommons.unl.edu/dissertations/AAI10840949/)

To learn more about how computers can be used to study literature, please see: ["Seven ways humanists are using computers to understand texts"](https://tedunderwood.com/2015/06/04/seven-ways-humanists-are-using-computers-to-understand-text/)





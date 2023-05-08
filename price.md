# GET POSSIBLE PRICES OF AN ARTICLE FROM AN HTML CONTENT

## ALGORITHMN

### DATA OUTPUT

### OVERALL PROCEDURE

1. Get text version of the html page and match it against a regular expression describing a price in your unit of
interest (XAF, EURO, DOLLAR, ... etc.) to find all prices in the text. For each substring which matches the
regex, save it start and end position.

2. For each of the found substrings, we now try to find in a well delimited space another substring which
(not totally) matches the name of your targeting article. W'll have to build a regex for that.

Let's define the search space for the name of our targeting article, the search space are substrings on both sides of the
substring matching the price regex and these substrings are delimited by another if exists first substrings matching the price
regex or simply the end/begining of text document if the don't. This is because the probability for the
existence of a name matching the article regex to be outside these boundries is very low and 0 for the later case.

### GENERATING A REGULAR EXPRESSION FOR MATCHING ARTICLE NAMES

The name of the article whose price you wish to know might probably be never what is presented to you on a web page.
This is because you might not spell it correctly or you wrote its name in your own language but unfortunately got a name
a bit similar but not exactly the same as the one you specified. So, how do you figure this out? Here I outline some of
the obvious steps we would use to generate a regular expression which matches articles similar to the one specified as
input.

#### UNICODE MAKEOVER

To avoid unintercipated inequalities between case folded substring, we decompose unicode characters found in those
substrings based on compatibility equivalence to obtain their ascii equivalent.

We also have to note the number of characters uncommon between strings that were needed to be decomposed
inorder for their comparison to return a true value.

#### EDIT DISTANCE

Use edit distance algorithm detect substrings ressemblance.

#### MEASURE PRECISION OF THE EXTRACTED ARTICLE MATCHED BY THE ARTICLE REGEX

The precision of the extracted article's name is measured by the edit distance, the how many unicode characters
were canonically decomposed to equate substrings and finally how far apart substrings in the requested articles
name are are in the extracted string.

### PERL CODE

### EXAMPLES

### ANALYSIS

### CONCLUSION

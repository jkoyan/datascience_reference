    ###Analyzing gun deaths in the US.
    The debate on Gun Control is a very contentious one, people on both sides of the debate put forth compelling arguments. Is there a way to approach the issue without any bias, well one way to do just that is to analyze any data related to gun deaths. Fortunately for the folks at [FiveThirtyEight](https://fivethirtyeight.com/) have already compiled the dataset which can be found here  https://github.com/fivethirtyeight/guns-data.   

    In this python notebook we will be analyzing and exploring the data to understand the demographics and social-economic factors associated with the dataset.

    We try to address the following questions in this project -
    1. What is the total numbers of deaths per year due to gun violence.
    2. What is the total number of deaths by Sex (Female\Male)
    3. What is the total number of deaths by Race, what is the rate of deaths per 100K of people by race.
    4. Filter the results by the intent i.e. How many of the deaths are accidental, homicide etc.

    The folder contains 4 files, viz.
    1. Basics.ipynb - ipython notebook contains code and markdown content, it uses the python 3.5 Kernel. The python code   uses lists (comprehension) and dictionaries to organize and categorize the data.
    2. README.md - Write-up on the project
    3. census.csv - Census data: Data from the file is used to get the population count by race, the information is then used to calculate the rate of deaths by guns per 100K of the population by race.
    4. guns.csv - Gund deaths data from 2012 to 2014. Every row represents a death due to gun violence.

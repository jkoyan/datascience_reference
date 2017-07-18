### Data Exploration and Visualization
In this project we'll explore how using the Pandas plotting functionality along with the Jupyter Notebook interface allows us to explore the data quickly using visualizations.

We'll be working with a dataset (file name - recent-grads.csv) on the job outcomes of students who graduated from college between 2010 and 2012. The original data on job outcomes was released by the American Community Survey, which conducts surveys and aggregates the data. FiveThirtyEight cleaned the dataset and release it on their [github repo](https://github.com/fivethirtyeight/data/tree/master/college-majors).

Each row in the dataset represents a different major in college and contains information on gender diversity, employment rates, median salaries and more. Here are some of the columns in the dataset - 

| Columns | Description |
| --------|-------------|
| Rank | Rank by median earnings (dataset is ordered by this column) |
| Major_code | Major code |
| Major | Major description |
| Major_category | Category of major |
| Total | Total number of people with major |
| Sample_size | Sample size (unweighted) of full-time |
| Men | Male graduates |
| Women | Female graduates |
| ShareWoman | Women as share of total |
| Employed | Number Employed |
| Median | Median salary of full-time, year-round workers |
| Low_wage_jobs | Number in low-wage service jobs |
| Full_time | Number employed 35 hours or more |
| Part_time | Number employed less than 36 hours |
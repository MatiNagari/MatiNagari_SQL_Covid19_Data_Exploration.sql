
# Covid-19 Data Exploration (SQL)
**Industry:** Public Health / Global Analytics  
**Target Metric:** Mortality Rates & Vaccination Penetration

---

## 1. Executive Summary
This project explores global Covid-19 data using SQL Server to identify death rates, infection rates, and vaccination rollouts across countries and continents. I developed a multi-stage analytical pipeline to track pandemic progression using real-world data sourced from *Our World in Data*.

## 2. Business Problem
During a global health crisis, data integrity is a major challenge. Public health officials need to understand not just total case counts, but the **velocity of spread** relative to **vaccination coverage**. This project addresses the need for a consolidated reporting layer that tracks real-time survival rates and population-level immunity trends.

## 3. Skills Demonstrated:
* Joins
* CTEs (Common Table Expressions)
* Temp Tables
* Window Functions
* Aggregate Functions
* Creating Views
* Converting Data Types
* NULLIF for safe division

## 4. Key Questions Explored:
* What percentage of the population died after contracting Covid?
* What percentage of the population was infected per country?
* Which countries had the highest infection and death rates?
* Which continents had the highest death counts?
* What percentage of each country's population got vaccinated over time?

## 5. Methodology
* **Data Integration:** Performed complex joins between Death and Vaccination datasets to correlate preventative measures with mortality outcomes.
* **Advanced Logic:** Used **Window Functions** to create "Rolling People Vaccinated" counts, allowing for time-series analysis of the vaccine rollout.
* **Optimization:** Developed **SQL Views** to store complex calculations, enabling faster loading for downstream BI tools like Power BI or Tableau.

## 6. Results & Recommendations
* **Mortality Disparities:** Identified significant variance in the "Death-to-Case" ratio across different continents, highlighting the impact of healthcare infrastructure.
* **Vaccination Velocity:** The analysis shows a clear "inflection point" where rolling vaccination totals began to correlate with a stabilization in death rates.
* **Data Strategy:** I learned that managing global datasets requires strict type-casting and error-handling (like `NULLIF`) to ensure that missing data in smaller nations doesn't skew global averages.

## 7. Tools Used:
* **Microsoft SQL Server**
* **SQL Server Management Studio (SSMS)**

---

**Data Source:** [Our World in Data — COVID-19 Dataset](https://ourworldindata.org/covid-deaths)  
**Author:** Mati Nagari

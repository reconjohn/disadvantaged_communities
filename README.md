[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.11476094.svg)](https://doi.org/10.5281/zenodo.11476094)
## Disadvantaged Communities in the U.S.

**Background**: Efforts to support disadvantaged communities have been prioritized through initiatives like Justice40, the Inflation Reduction Act (IRA), and the Bipartisan Infrastructure Law (BIL). Identifying disadvantaged communities involves several datasets with associated variables related to vulnerability indicators and scores. There are three key datasets:

1. [Climate and Economic Justice Screening Tool (CEJST)](https://screeningtool.geoplatform.gov/en/methodology#3/33.47/-97.5) from the White House Council on Environmental Quality (CEQ).
2. [Energy Justice Mapping Tool](https://energyjustice.egs.anl.gov/) from the Department of Energy (DOE) Office of Economic Impact & Diversity.
3. [Environmental Justice Screening Tool](https://www.epa.gov/system/files/documents/2023-06/ejscreen-tech-doc-version-2-2.pdf) from the Environmental Protection Agency (EPA) Office of Environmental Justice and External Civil Rights.

**Problem**:
1. Each dataset employs similar but distinct criteria and outcomes.
2. The unique IDs or GEOIDs differ across datasets. CEJST uses the 2010 census boundaries, while the Energy Justice Mapping Tool and the Environmental Justice Screening Tool are based on the 2019 and 2021 census boundaries, respectively.
------------------------

To address these issues, this dataset consolidates information on disadvantaged communities and their associated variables by combining the three distinct datasets:

- **CEJST**: Provides binary data indicating whether a tract is a disadvantaged community. A community is classified as disadvantaged if it meets any of the following thresholds: 1) one or more indicators within categories such as climate change, energy, health, housing, pollution, transportation, and water & wastewater, coupled with low income; 2) one or more indicators in workforce development category and education; or 3) tribal lands. Environment and pollution indicators come from the EPA, while socio-demographic indicators are from the American Community Survey (ACS) for 2015-2019.

- **Energy Justice Mapping Tool**: Offers a DAC score, a continuous variable representing the sum of the 36 indicator percentiles. It includes environment, pollution, and socio-demographic indicators from the EPA and ACS (2015-2019). 

- **Environmental Justice Screening Tool**: Includes the 13 Environmental Justice (EJ) Index and Supplemental Index. These continuous variables are weighted with socio-demographic indicators from ACS (2017-2021).

### Data Descriptions
- **Unit of Analysis**: Census tract
- **Geometry**:  2021 census boundaries
- **Columns**:
    - Socio-demographic indicators
    - 13 Environmental Justice (EJ) index values
    - 13 Supplemental index values
    - Binary indicator for disadvantaged community classification
    - Disadvantaged Community (DAC) scores 
- **Datasets**:
    - `results/DAC.csv`: Contains all columns from the three datasets.
    - `results/DAC_s.csv`: A shorter version, including socio-demographic indicators and EJ and Supplemental indices (Environmental Justice Screening Tool), disadvantaged community classification (CEJST), and DAC scores (Energy Justice Mapping Tool). 
- **Code**:
    - `syntax/code.R`: This script illustrates the methodology for merging the three datasets, culminating in the creation of the two CSV files located in the results directory. 


### Purpose:
The dataset aims to help researchers identify overall disadvantaged communities or determine which specific communities are classified as disadvantaged. By consolidating these datasets, researchers can more effectively analyze and compare the various criteria used to define disadvantaged communities, enhancing the comprehensiveness of their studies.

##### Note
For complete data descriptions and sources, please refer to the original datasets.
* [Climate and Economic Justice Screening Tool (CEJST)](https://screeningtool.geoplatform.gov/en/methodology#3/33.47/-97.5) 
* [Energy Justice Mapping Tool](https://energyjustice.egs.anl.gov/) 
* [Environmental Justice Screening Tool](https://www.epa.gov/system/files/documents/2023-06/ejscreen-tech-doc-version-2-2.pdf) 
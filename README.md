# 婚姻平權及性別教育公投連署資料檔及分析

這是文章[連署婚姻平權的朋友在哪裡？](https://medium.com/@amossclaire/%E9%80%A3%E7%BD%B2%E5%A9%9A%E5%A7%BB%E5%B9%B3%E6%AC%8A%E7%9A%84%E6%9C%8B%E5%8F%8B%E5%9C%A8%E5%93%AA%E8%A3%A1-f815f2793167)所使用的資料及作圖分析 R Script。

![鄉鎮市區大學畢業比例及平權公投連署比例](marriage_equality_college.png?raw=true)

## 資料

### 原始資料

- `marriage_equality.csv` 婚姻平權公投分區連署人數表
- `gender_education.csv` 性別教育公投分區連署人數表
- `demographic.csv` 檔案太大 github 不給傳，是人口統計資料，來自內政部資料開放平臺[15歲以上現住人口按性別、年齡、婚姻狀況及教育程度分](https://data.moi.gov.tw/MoiOD/Data/DataDetail.aspx?oid=4E7FFDCC-17EC-4E5C-9DD7-780C2890AF6B)資料集，上平台下載即可。

### 統整資料：
- `top_20.csv` 婚姻平權公投連署比例前 20 名鄉鎮市區
- `data.csv` R Script 最終作圖資料檔，只想重新畫圖，可以載這個就好囉

## R Script

`eda.R`

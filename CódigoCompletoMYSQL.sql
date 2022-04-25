
# Analizar duplicados y valores null

SELECT DISTINCT ProductName
FROM Sales;

SELECT *
FROM Sales
WHERE Price IS NULL;

SELECT Price
FROM Sales
WHERE Quantity IS NULL;

# Creacion de tablas temporales

DROP TABLE IF EXISTS SalesTemp;

CREATE TEMPORARY TABLE SalesTemp
SELECT *, ROUND(Price*Quantity, 2) AS TotalSpend
FROM Sales;

DROP TABLE IF EXISTS SalesTemp2;
CREATE TEMPORARY TABLE SalesTemp2
SELECT *, ROUND(Price*Quantity, 2) AS TotalSpend
FROM Sales;

# 15 Cleintes que más gastan en la compañia.

SELECT 
  CustomerNo, 
  ROUND(SUM(TotalSpend), 2) AS Spend
FROM SalesTemp
GROUP BY CustomerNo
ORDER BY Spend DESC
LIMIT 15;

# Paises con mas ventas excluyendo Reino Unido

SELECT 
  Country, 
  ROUND(SUM(TotalSpend), 2) AS CountrySpend
FROM SalesTemp
WHERE Country <> 'United Kingdom'
GROUP BY Country
ORDER BY CountrySpend DESC;

# Prodcuto más comprado

SELECT *
FROM (SELECT 
        ProductName, 
        SUM(Quantity) OVER (PARTITION BY ProductName) AS cantidadvendida
      FROM SalesTemp) AS ASfg 
GROUP BY ProductName, cantidadvendida
ORDER BY cantidadvendida DESC
;


# Producto que genero más ingreso

SELECT ProductName, 
       ROUND(SUM(TotalSpend), 2) AS ProdcutSale
FROM SalesTemp
GROUP BY ProductName
ORDER BY ProdcutSale DESC;

# Clientes con sus respectivos paises y gastos.

SELECT CustomerNo, 
       Country, 
       ROUND(SUM(TotalSpend),2) AS Spend
FROM SalesTemp
GROUP BY CustomerNo, Country
ORDER BY Spend DESC
;

# Total Acumulativo de usuarios activos por mes 


SELECT 
  Fecha, 
  CompradoresActivos,
  SUM(CompradoresActivos) OVER (ORDER BY Fecha ASC) AS CompradoresActivosRT
FROM (SELECT 
        DATE_FORMAT(firstbuy,'%Y-%m') AS Fecha,
        COUNT(DISTINCT CustomerNo) AS CompradoresActivos
      FROM (SELECT 
              CustomerNo, 
              MIN(Date) AS firstbuy
            FROM SalesTemp
            GROUP BY CustomerNo) AS dg
      GROUP BY Fecha
      ORDER BY Fecha) AS dgs
ORDER BY Fecha ASC
;

# Crecimiento Acumulativo de compradores activos por mes

SELECT 
  Fecha, 
  CompradoresActivos,
  ROUND((CompradoresActivos - CompradoresActivosRT) / CompradoresActivosRT, 2) AS Crecimiento
FROM (SELECT 
        Fecha, 
        CompradoresActivos,
        COALESCE (LAG(CompradoresActivos) OVER (ORDER BY Fecha ASC), 1) AS CompradoresActivosRT
      FROM (SELECT  
              DATE_FORMAT(firstbuy,'%Y-%m') AS Fecha,
              COUNT(DISTINCT CustomerNo) AS CompradoresActivos
            FROM (SELECT 
                    CustomerNo, 
                    MIN(Date) AS firstbuy
                  FROM SalesTemp
                  GROUP BY CustomerNo) AS dg
           GROUP BY Fecha
           ORDER BY Fecha) AS dgs
     ORDER BY Fecha ASC) AS dgba
;

# Ventas por comprador. IPPC = Ingreso Promedio por Comprador.

SELECT ROUND(AVG(Ingreso)) AS IPPC
FROM (SELECT 
        CustomerNo,   
        SUM(Price*Quantity) AS Ingreso
FROM SalesTemp
GROUP BY CustomerNo) AS lgh
;

# Frecuencia de ordenes

SELECT 
  ordenes,
  COUNT(DISTINCT CustomerNo) AS compradores
FROM (SELECT 
        CustomerNo, 
        COUNT(DISTINCT TransactionNo) AS ordenes
      FROM SalesTemp
      GROUP BY CustomerNo) AS fad
GROUP BY ordenes
ORDER BY ordenes ASC;


# Dividir a los compradore en 4 categorias dependiendo sus compras en productos de la empresa.


SELECT 
  CASE
    WHEN Ingreso < '300'
    THEN 'Comprador Moderado'
    WHEN Ingreso > '300' and Ingreso < '2500'
    THEN 'Comprador Estandar'
    WHEN Ingreso > '2500' and Ingreso < '10000'
    THEN 'Comprador Estandar Plus'
    ELSE 'Comprador Premium'
    END AS Tipo,
    COUNT(DISTINCT CustomerNo) AS cantidad
FROM (SELECT 
        CustomerNo, 
        ROUND(SUM(TotalSpend), 2) AS Ingreso
     FROM SalesTemp
     GROUP BY CustomerNo) AS fga
GROUP BY Tipo
ORDER BY cantidad DESC

# Nota: En PostreSQL y otras RDBMS se puede lograr el mismo resultado de manera mas práctica con el siguiente código: "SELECT PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY by value)"
;

# Unir la tabla con los tipos de compradores a la tabla general

DROP TABLE IF EXISTS SalesTemp3;
CREATE TEMPORARY TABLE SalesTemp3
SELECT CustomerNo,
  CASE
    WHEN Ingreso < '300'
    THEN 'Moderado'
    WHEN Ingreso > '300' and Ingreso < '2500'
    THEN 'Estandar'
    WHEN Ingreso > '2500' and Ingreso < '10000'
    THEN 'Estandar Plus'
    ELSE 'Premium'
    END AS Tipo
FROM (SELECT 
        CustomerNo, 
        ROUND(SUM(TotalSpend), 2) AS Ingreso
     FROM SalesTemp
     GROUP BY CustomerNo) AS fga
GROUP BY CustomerNo, Tipo
;



SELECT TransactionNo, 'Date', ProductNo, ProductName, Price, Quantity, SalesTemp.CustomerNo, Tipo
FROM SalesTemp
LEFT JOIN SalesTemp3 
ON SalesTemp3.CustomerNo=SalesTemp.CustomerNo;


;

# Lugar de residencia de los compradores que estan por encima del percetil 0.95 en terminos de capital invertido en los productos de la empresa. 

SELECT Country
FROM Sales
WHERE CustomerNo in (SELECT 
                       CustomerNo
                       FROM (SELECT 
                               CustomerNo, 
                               ROUND(SUM(TotalSpend), 2) AS Ingreso,
                               ROUND( PERCENT_RANK() OVER (ORDER BY ROUND(SUM(TotalSpend), 2)) ,2) Percentil
                             FROM SalesTemp2
                             GROUP BY CustomerNo) AS fakls
                       WHERE Ingreso > (SELECT 
                                          max(Ingreso)
                                          FROM (SELECT 
                                                  CustomerNo, 
                                                  ROUND(SUM(TotalSpend), 2) AS Ingreso,
                                                  ROUND( PERCENT_RANK() OVER (ORDER BY ROUND(SUM(TotalSpend), 2)) ,2) Percentil
                                                FROM SalesTemp
                                                GROUP BY CustomerNo) AS fakl
                                          WHERE percentil = '0.95'))

GROUP BY Country

;

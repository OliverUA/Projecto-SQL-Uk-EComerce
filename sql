SELECT DISTINCT ProductName
FROM Sales;

SELECT *
FROM Sales
WHERE Price IS NULL;

SELECT Price
FROM Sales
WHERE Quantity IS NULL;

DROP TABLE IF EXISTS SalesTemp;

CREATE TEMPORARY TABLE SalesTemp
SELECT *, ROUND(Price*Quantity, 2) AS TotalSpend
FROM Sales;

DROP TABLE IF EXISTS SalesTemp2;
CREATE TEMPORARY TABLE SalesTemp2
SELECT *, ROUND(Price*Quantity, 2) AS TotalSpend
FROM Sales;

# 15 Cleintes que mAS gAStan en la compañia.

SELECT 
  CustomerNo, 
  ROUND(SUM(TotalSpend), 2) AS Spend
FROM SalesTemp
GROUP BY CustomerNo
ORDER BY Spend DESC
LIMIT 15;

# Countries with most sales besides UNited Kingdom

SELECT 
  Country, 
  ROUND(SUM(TotalSpend), 2) AS CountrySpend
FROM SalesTemp
WHERE Country <> 'United Kingdom'
GROUP BY Country
ORDER BY CountrySpend DESC;

# Prodcuto mAS comprado

SELECT *
FROM (SELECT 
        ProductName, 
        SUM(Quantity) OVER (PARTITION BY ProductName) AS cantidadvendida
      FROM SalesTemp) AS ASfg 
GROUP BY ProductName, cantidadvendida
ORDER BY cantidadvendida DESC
;


# Producto que genero mAS ingreso

SELECT ProductName, 
       ROUND(SUM(TotalSpend), 2) AS ProdcutSale
FROM SalesTemp
GROUP BY ProductName
ORDER BY ProdcutSale DESC;

# Clientes con sus respectivos paises y gAStos.

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
  UsuariosActivos,
  SUM(UsuariosActivos) OVER (ORDER BY Fecha ASC) AS UsuariosActivosRT
FROM (SELECT 
        DATE_FORMAT(firstbuy,'%Y-%m') AS Fecha,
        COUNT(DISTINCT CustomerNo) AS UsuariosActivos
      FROM (SELECT 
              CustomerNo, 
              MIN(Date) AS firstbuy
            FROM SalesTemp
            GROUP BY CustomerNo) AS dg
      GROUP BY Fecha
      ORDER BY Fecha) AS dgs
ORDER BY Fecha ASC
;

# Crecimiento Acumulativo de usuarios activos por mes (CAMBIAR USUARIOS POR COMPRADORES)

SELECT 
  Fecha, 
  UsuariosActivos,
  ROUND((UsuariosActivos - UsuariosActivosRT) / UsuariosActivosRT, 2) AS growth
FROM (SELECT 
        Fecha, 
        UsuariosActivos,
        COALESCE (LAG(UsuariosActivos) OVER (ORDER BY Fecha ASC), 1) AS UsuariosActivosRT
      FROM (SELECT  
              DATE_FORMAT(firstbuy,'%Y-%m') AS Fecha,
              COUNT(DISTINCT CustomerNo) AS UsuariosActivos
            FROM (SELECT 
                    CustomerNo, 
                    MIN(Date) AS firstbuy
                  FROM SalesTemp
                  GROUP BY CustomerNo) AS dg
           GROUP BY Fecha
           ORDER BY Fecha) AS dgs
     ORDER BY Fecha ASC) AS dgba
;

# VentAS por comprador. IPPC = Ingreso Promedio por Comprador.

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


# Dividir a los compradore en 4 categoriAS dependiendo sus comprAS en productos de la empresa. Si compro menos de 300usd en poductos son "", etc...


SELECT 
  CASE
    WHEN Ingreso < '300'
    THEN 'Comprador Chico'
    WHEN Ingreso > '300' and Ingreso < '2500'
    THEN 'estandar'
    WHEN Ingreso > '2500' and Ingreso < '10000'
    THEN 'Comprador Alto'
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

# Note that in PostreSQL and other RDBMS it can be done with: "SELECT PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY by value)"
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

GROUP BY Country;


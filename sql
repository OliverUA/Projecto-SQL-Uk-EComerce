Select distinct ProductName
from Sales;

Select *
from Sales
where Price IS NULL;

Select *Price
from Sales
where Quantity IS NULL;

DROP TABLE IF EXISTS SalesTemp;
CREATE TEMPORARY TABLE SalesTemp
select *, round(Price*Quantity, 2) as TotalSpend
from Sales;

DROP TABLE IF EXISTS SalesTemp2;
CREATE TEMPORARY TABLE SalesTemp2
select *, round(Price*Quantity, 2) as TotalSpend
from Sales;

# 15 Cleintes que mas gastan en la compañia.

select CustomerNo, ROUND(SUM(TotalSpend), 2) as Spend
from SalesTemp
group by CustomerNo
ORDER BY Spend desc
LIMIT 15;

# Countries with most sales besides UNited Kingdom

select Country, ROUND(Sum(TotalSpend), 2) as CountrySpend
from SalesTemp
WHERE Country <> 'United Kingdom'
group by Country
ORDER BY CountrySpend DESC;

# Prodcuto mas comprado

Select *
from (
select ProductName, sum(Quantity) over (partition by ProductName) as cantidadvendida
from SalesTemp
) as asfg 
group by ProductName, cantidadvendida
order by cantidadvendida desc
;


# Producto que genero mas ingreso

select ProductName, ROUND(Sum(TotalSpend), 2) as ProdcutSale
from SalesTemp
group by ProductName
Order by ProdcutSale desc;

# Clientes con sus respectivos paises y gastos.

select CustomerNo, Country, ROUND(SUM(TotalSpend),2) as Spend
from SalesTemp
group by CustomerNo, Country
ORDER BY Spend DESC
;

# Total Acumulativo de usuarios activos por mes 


select Fecha, UsuariosActivos,
sum(UsuariosActivos) OVER (ORDER BY Fecha ASC) as UsuariosActivosRT
FROM (select  
       DATE_FORMAT(firstbuy,'%Y-%m') as Fecha,
       count(distinct CustomerNo) as UsuariosActivos
      from (select 
             CustomerNo, 
             MIN(Date) as firstbuy
            from SalesTemp
            group by CustomerNo) as dg
      group by Fecha
      order by Fecha) as dgs
ORDER BY Fecha ASC
;

# Crecimiento Acumulativo de usuarios activos por mes (CAMBIAR USUARIOS POR COMPRADORES)

select Fecha, UsuariosActivos,
ROUND((UsuariosActivos - UsuariosActivosRT) / UsuariosActivosRT, 2) as growth
from (select Fecha, UsuariosActivos,
COALESCE (LAG(UsuariosActivos) OVER (ORDER BY Fecha ASC), 1) as UsuariosActivosRT
FROM (select  
       DATE_FORMAT(firstbuy,'%Y-%m') as Fecha,
       count(distinct CustomerNo) as UsuariosActivos
      from (select 
             CustomerNo, 
             MIN(Date) as firstbuy
            from SalesTemp
            group by CustomerNo) as dg
      group by Fecha
      order by Fecha) as dgs
ORDER BY Fecha ASC) as dgba
;

# Ventas por comprador. IPPC = Ingreso Promedio por Comprador.

Select ROUND(AVG(Ingreso)) as IPPC
From (
Select CustomerNo, sum(Price*Quantity) as Ingreso
FROM SalesTemp
GROUP BY CustomerNo
) as lgh
;

# Frecuencia de ordenes

Select ordenes,
Count(DISTINCT CustomerNo) as compradores
from (select CustomerNo, 
count(distinct TransactionNo) as ordenes
from SalesTemp
GROUP BY CustomerNo) as fad
GROUP BY ordenes
ORDER BY ordenes asc;


# Dividir a los compradore en 4 categorias dependiendo sus compras en productos de la empresa. Si compro menos de 300usd en poductos son "", etc...


select 
CASE
when Ingreso < '300'

then 'Comprador Chico'

when Ingreso > '300' and Ingreso < '2500'

then 'estandar'

when Ingreso > '2500' and Ingreso < '10000'

then 'Comprador Alto'

Else 'Comprador Premium'

end as loco,

count(distinct CustomerNo) as cantidad


from (select CustomerNo, Round(Sum(TotalSpend), 2) as Ingreso
     From SalesTemp
     GROUP BY CustomerNo) as fga

group by loco

order by cantidad desc

# Note that in PostreSQL and other RDBMS it can be done with: "SELECT PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY by value)"
;

# Lugar de residencia de los compradores que estan por encima del percetil 0.95 en terminos de capital invertido en los productos de la empresa. 

Select Country
From Sales
Where CustomerNo in (

select CustomerNo
from (
select CustomerNo, Round(Sum(TotalSpend), 2) as Ingreso,
     ROUND( PERCENT_RANK() OVER (ORDER BY Round(Sum(TotalSpend), 2)) ,2) Percentil
     From SalesTemp2
     GROUP BY CustomerNo
) as fakls
where Ingreso > (
Select max(Ingreso)
from (
select CustomerNo, Round(Sum(TotalSpend), 2) as Ingreso,
     ROUND( PERCENT_RANK() OVER (ORDER BY Round(Sum(TotalSpend), 2)) ,2) Percentil
     From SalesTemp
     GROUP BY CustomerNo
) as fakl
where percentil = '0.95'
)
)

group by Country
;

Select CustomerNo, max(TotalSpend) as tt, top(ProductName, 2)
from SalesTemp
group by CustomerNo
order by tt desc;

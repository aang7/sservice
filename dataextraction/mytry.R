file <- "datatestDengueClasico2008.csv"
headers = read.csv(file, skip = 2, header = FALSE, nrows = 1, as.is = T)
df = read.csv(file, skip = 3, header = FALSE)
mweekstest = read.csv(file, skip = 1, header = FALSE, nrows = 1)
colnames(df)= headers
hac_name <- 'H Ac.'
mac_name <- 'M Ac.'
sac_name <- 'Sem.'

hac <- c()
mac <- c()
sac <- c() 
nweeks <- length(which((names(df) == 'Sem.')))

estados <- df$E.F.
estadosvec <- rep(estados, each = nweeks) #repite edos por cantidad de semanas


nrows <- length(df[ ,1])
for (i in 1:nrows)
{
    mac <- append(mac, c(t(df[i, which((names(df) == mac_name))])))#acumulado mujer
    hac <- append(hac, c(t(df[i, which((names(df) == hac_name))])))#acumulad hombre
    sac <- append(sac, c(t(df[i, which((names(df) == sac_name))])))#casos en semana
}


#    summary(mac, hac, sac)
mydf <- data.frame(estadosvec, sac, mac, hac)

mweekstest <- mweekstest[, -(which(sapply(mweekstest, class) == "logical"))]
mweekstest <- mweekstest[, -1] #delete first element
fweeks = c()
for(i in 1:nrows)
    fweeks <- append(fweeks, c(t(mweekstest)))


df2008 <- data.frame(estadosvec, fweeks, sac, mac, hac)
colnames(df2008) <- c("estado", "semana", "acumsemana", "acummujer", "acumhombre")
df2008$acummujer
semana7 = df2008[df2008$semana == 7, ]

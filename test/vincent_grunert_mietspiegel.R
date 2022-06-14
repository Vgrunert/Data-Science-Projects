library(readxl)
library(ggplot2)
library(dplyr)
library(reshape2)
library(lmtest)
library(sandwich)
library(lmtest)
library(rpart)
library(rpart.plot)

options(scipen = 1e+9, device = "X11", "width"=500)
dev.new()

path <- "/home/vincent/Dropbox/University/Statistik/KURSE/CURRENT/master/stat_fallstudien/Beispiel_Mietspiegel.xlsx"

miete <- read_xlsx(path, sheet = 2)
names(miete) <- c(
  "Nettomiete", "Wohnflaeche", "Zimmeranzahl", "Baujahr", "Gute_Wohnanlage", "Beste_Wohnanlage", "Warmwasservers.", "Zentralheizung", "Gekacheltes_Bad", "Bes_Zusatzausst_Bad", "Gehobene_Kueche")


# Ich bin Immobilienmakler und betreibe in Wien ein Firma. Wir wollen eine genauere Analyse des Marktes für Mietwohnungen durchführen. 
# Uns interessiert, was sind die Key Treiber für den Mietpreis bei privater Wohnungsmiete in unserer Stadt. Wovon hängt die höhe der Nettomiete ab?

# Ich beauftrage Sie ein entsprechendes Untersuchungsdesign zu erstellen. 

# Univariate Analysesn
# a) Kennzahlen
#     Mittelwert, Standardabweichung, Schiefe, Minimum, 1.Quantil, Median, 3.Quantil, Maxium
#     Modus, eventuell 2., 3. etc. größte Werte
# b) Grafische Darstellung
# c) Datenkontrolle, Qualitätskontrolle
# d) Ziel: machen Sie sich ein Bild von den Objekten, die
# Sie vor sich haben.


attach(miete)

# names(miete)
# erstelle eine neue variable: alter = 2003 - bj 

is_binary <- function(x) x == 0 | x == 1
daten_kontrolle <- function(daten = miete){
  # daten kontrollieren
  # missing values?
  fehlende_werte <- any(is.na(daten))

  # keine zahl?
  keine_zahl <- any(apply(miete, 2, is.nan))

  # sind alles zahlen?
  alles_zahlen <- all(apply(miete, 2, is.numeric))

  # negarive zahlen (duerften nicht vorkommen)
  neg_werte <- any(miete < 0)

  # alle anderen variablen haben nur null und eins als definitionsbereich. dies laesst sich leicht testen
  alles_binaer <- all(apply(datheteroskedasticity robust standard errors en[,5:ncol(daten)], 2, function(x) all(is_binary(x))))

  # teste ob alle bedingungen erfuellt sind
  !fehlende_werte & !keine_zahl & alles_zahlen & !neg_werte & alles_binaer
}

daten_kontrolle(miete)

# problem baujahr
# 1) halbjahreszahlen -> kein problem weil die daten ohnehin zusammengefasst werden
# 2) Viele Beobachtungen im Jahr 1918 (macht offensichtlich keine Sinn) wie 1) wir fassen die Jahre in 20 Jahreskategorien zusammen

nm <- miete["Nettomiete"]
nm <- pull(nm) 
wfl <- miete["Wohnflaeche"]
wfl <- pull(wfl) 
rooms <- miete["Zimmeranzahl"]
rooms <- pull(rooms) 
bj <- miete["Baujahr"]
bj <- pull(bj) 
alter <- 2003 - bj
wohngut <- miete["Gute_Wohnanlage"]
wohngut <- pull(wohngut)
wohnbest <- miete["Beste_Wohnanlage"]
wohnbest <- pull(wohnbest)

# folgende drei variablen sind ungewohnlich kodiert in dem sinne dass 0 fuer ja und 1 fuer nein steht
# wir schaffen somit drei neue variablen die wir als negierte originale, dh warmwasserversorgung -> keine warmwasserversorgung etc benennen
ww0 <- miete["Warmwasservers."]
ww0 <- pull(ww0)
ohne_ww0 <- ww0

zh0 <- miete["Zentralheizung"]
zh0 <- pull(zh0)
ohne_zh0 <- zh0

badkach0 <- miete["Gekacheltes_Bad"]
badkach0 <- pull(badkach0)
ohne_badkach0 <- badkach0

# durchschn_wfl <- wfl / rooms

# wir schaffen eine neue variable Wohnqualitaet die aus drei Gruppen besteht,
# "Normal" fuer alle wohnungen die nicht in wohngut oder wohnbest sind
# "Gut" fuer alle wohnungen die in "wohngut sind"
# "Beste" fuer die wohnungen die in wohnbest sind aber wir muessen auf ueberschneidungen zwischen wohngut und wohnbest aufpassen
which(wohngut == 1 & wohnbest == 1)
# gibt keine 

# also wenn eine wohnung nicht in wohngut oder wohnbest dann sagen wir sie ist normal
# which(wohngut == 0 & wohnbest == 0)
# also wenn eine wohnung nicht in wohngut oder wohnbest dann sagen wir sie ist normal
# which(wohngut == 0 & wohnbest == 0)
wohnnorm <- ifelse(wohngut == 0 & wohnbest == 0, 1, 0)
wohnanl <- ifelse(wohnnorm == 1, 1, ifelse(wohngut == 1, 2, 3))
wohnanl <- factor(wohnanl, labels = c("Normal", "Gut", "Beste"))

badextra <- miete["Bes_Zusatzausst_Bad"]
badextra <- pull(badextra)
kueche <- miete["Gehobene_Kueche"]
kueche <- pull(kueche)       

# speicher alten miete datensatz
miete_alt <- miete
# table(miete_alt$Baujahr)
# schaffe neuen mit transformierten daten
miete <- data.frame(
  Nettomiete = nm,
  Wohnflaeche = wfl, 
  Zimmeranzahl = rooms,
  Alter_Gruppiert = cut(2003-miete_alt$Baujahr, breaks = c(0, 20, 40, 60, 80, Inf), labels = c("(0,20]","(20,40]",  "(40,60]",  "(60,80]", "(80,80+]")), 
  Wohnanlage = wohnanl,
  Ohne_Warmwasservers = ohne_ww0,
  Ohne_Zentralheizung = ohne_zh0,
  Ohne_Gekacheltes_Bad = ohne_badkach0,
  Extra_Badausst = badextra,
  Gehobene_Kueche = kueche
)

head(miete)


# univariate analysen
# nettomiete
# "grobstistiken"

nm <- miete$Nettomiete

# zahlen gerundet
nm_stats <- c(round(min(nm)-1), round(quantile(nm, 0.25)), round(mean(nm)), round(quantile(nm, 0.75)), round(quantile(nm, 0.95)), round(max(nm)))

cat_nm <- cut(nm, nm_stats, dig.lab = 5)

# anzahl an beobachtungen in den jeweiligen kategorien
table_nm_cat <- table(cat_nm)

# speicher im df fuer die grafische aufbearbeitung
df_nm <- data.frame(table_nm_cat)

# cumsums
cumsum_cat_nm <- cumsum(table_nm_cat)
names(cumsum_cat_nm) <- paste("Nmiete <=", nm_stats[-1])
df_cumsum_nm <- data.frame(Cat = names(cumsum_cat_nm), Freq = cumsum_cat_nm)


# boxplot: einige ausreisser nach oben
ggplot(miete) + geom_boxplot(aes(y = nm))

# histogram
# ggplot(df_nm, aes(x=cat_nm, y = Freq)) + geom_bar(stat = "identity", fill = c("grey35", "red", "red", "grey35", "grey35")) + geom_text(aes(label = Freq), vjust = 2 ) + labs(title="Mietpreiskategorien",
#         x ="Preisintervall", y = "Haeufigkeit")

# histogram der kategorien 
ggplot(df_nm, aes(x=cat_nm, y = Freq)) + geom_bar(stat = "identity", fill = c("grey35", "red", "red", "grey35", "grey35")) + geom_text(aes(label = Freq), vjust = -1 ) + labs(title="Mietpreiskategorien",
        x =" ", y = "Haeufigkeit")+ ylim(c(0, 320)) 

# kummulierte haeufigkeiten
df_cumsum_nm %>% arrange(Freq) %>% mutate(name = factor(Cat, levels=names(cumsum_cat_nm))) %>% ggplot(aes(x=name, y = Freq, label = scales::percent(Freq/1000))) + geom_bar(stat = "identity", fill = c("grey35", "red", "grey35", "grey35", "grey35")) + geom_text(vjust = -1) + labs(title="Mietpreiskategorien Kummuliert", x ="Preisintervall", y = "Haeufigkeit")+ ylim(c(0, 1050)) 


# nicht normalverteilt (abwarten bis wir auf die zeit bedingen)
shapiro.test(nm)

# ausreisser
if(has_outlier(nm)) cbind(index = get_outlier(nm), value = nm[get_outlier(nm)])

# wohnflaeche
wfl <- miete$Wohnflaeche
wfl_stats <- c(round(min(wfl))-1, round(quantile(wfl, 0.25)), round(mean(wfl)), round(quantile(wfl, 0.75)), round(quantile(wfl, 0.95)), round(max(wfl)))

cat_wfl <- cut(wfl, wfl_stats)

# haeufigkeiten der kategorien
table_wfl_cat <- table(cat_wfl)

# cusum 
cumsum_cat_wfl <- cumsum(table_wfl_cat)
names(cumsum_cat_wfl) <- paste("Wflaeche <=", wfl_stats[-1])
df_cumsum_wfl <- data.frame(Cat = names(cumsum_cat_wfl), Freq = cumsum_cat_wfl)

# speicher in einem data frame fuer die visualisierung
df_wfl <- data.frame(table_wfl_cat)

# einige ausreisser nach oben
ggplot(miete) + geom_boxplot(aes(y = wfl)) + labs(title="Wohnflaeche", x ="", y = "Haeufigkeit")
# boxplot(wf)

# histogram

# histogram der kategorien 
ggplot(df_wfl, aes(x=cat_wfl, y = Freq)) + geom_bar(stat = "identity", fill = c("grey35", "red", "red", "grey35", "grey35")) + geom_text(aes(label = Freq), vjust = -1 ) + labs(title="Mietpreiskategorien",
        x ="Wohnflaecheintervall", y = "Haeufigkeit") + ylim(c(0, 320))

# kummulierte haeufigkeiten
df_cumsum_wfl %>% arrange(Freq) %>% mutate(name = factor(Cat, levels=names(cumsum_cat_wfl))) %>% ggplot(aes(x=name, y = Freq, label = scales::percent(Freq/1000))) + geom_bar(stat = "identity", fill = c("grey35", "red", "grey35", "grey35", "grey35")) + geom_text(vjust = -1) + labs(title="Wohnflaechen Kummuliert", x ="Wohnflaeche", y = "Haeufigkeit") + ylim(c(0, 1050))

if(has_outlier(wfl)) cbind(index = get_outlier(wfl), value = nm[get_outlier(wfl)])


# zimmer
rooms <- miete$Zimmeranzahl
# summary(rooms)

# haeufigkeiten der kategorien
table_rooms <- table(rooms)

# cusum 
cumsum_rooms <- cumsum(table_rooms)
names(cumsum_rooms) <- paste("Zimmer <=", names(table_rooms))
df_cumsum_rooms <- data.frame(Cat = names(cumsum_rooms), Freq = cumsum_rooms)

# speicher in einem data frame fuer die visualisierung
df_rooms <- data.frame(table_rooms)

# histogram der kategorien 
ggplot(df_rooms, aes(x=rooms, y = Freq)) + geom_bar(stat = "identity", fill = c("grey35", "red", "red","grey35", "grey35", "grey35")) + geom_text(aes(label = Freq), vjust = -1 ) + labs(title="Zimmeranzahl",
        x ="", y = "Haeufigkeit") + ylim(c(0, 420))

# kummulierte haeufigkeiten
df_cumsum_rooms %>% arrange(Freq) %>% mutate(name = factor(Cat, levels=names(cumsum_rooms))) %>% ggplot(aes(x=name, y = Freq, label = scales::percent(Freq/1000))) + geom_bar(stat = "identity",fill = c("grey35", "grey35", "red","grey35", "grey35", "grey35")) + geom_text(vjust = -1) + labs(title="Zimmeranzahl Kummuliert", x ="", y = "Haeufigkeit") + ylim(c(0, 1050))




# haeufigkeiten der kategorien
alter <- miete$Alter_Gruppiert
table_alter <- table(alter)
names(table_alter) <- names(table_alter)

# cusum 
cumsum_alter <- cumsum(table_alter)
names(cumsum_alter) <- paste("Alter <=", c(20, 40, 60, 80, "80+"))
df_cumsum_alter <- data.frame(Cat = names(cumsum_alter), Freq = cumsum_alter)

# speicher in einem data frame fuer die visualisierung
df_alter <- data.frame(table_alter)

# histogram der kategorien 
ggplot(df_alter, aes(x= Var1, y = Freq)) + geom_bar(stat = "identity", fill = c("grey35", "grey35", "grey35","grey35", "red")) + geom_text(aes(label = Freq), vjust = -1,size = 2.5 ) + labs(title="Alter", x ="", y = "Haeufigkeit") + ylim(c(0, 350)) 

# kummulierte haeufigkeiten
df_cumsum_alter %>% arrange(Freq) %>% mutate(name = factor(Cat, levels=names(cumsum_alter))) %>% ggplot(aes(x=name, y = Freq, label = scales::percent(Freq/1000))) + geom_bar(stat = "identity", fill = c("grey35", "grey35", "red","grey35", "grey35")) + geom_text(vjust = -1) + labs(title="Alter Kummuliert", x ="", y = "Haeufigkeit") + ylim(c(0, 1050))



names(miete)
table_wanl <- table(miete$Wohnanl)
table_ohne_ww <- table(miete$Ohne_Warmwasservers)
table_ohne_zh <- table(miete$Ohne_Zentralheizung)
table_ohne_badkach <- table(miete$Ohne_Gekacheltes_Bad)
table_badextra <- table(miete$Extra_Badausst)
table_kueche <- table(miete$Gehobene_Kueche)

ggplot(data.frame(table_wanl), aes(x = Var1, y = Freq)) + geom_bar(stat = "identity") + geom_text(label = table_wanl, vjust = -1) + labs(title="Wohnanlage", x ="", y = "Haeufigkeit") + ylim(c(0,610))

ggplot(data.frame(table_ohne_ww), aes(x = Var1, y = Freq)) + geom_bar(stat = "identity") + geom_text(label = table_ohne_ww, vjust = -1) + labs(title="Ohne Warmwasserversorgung", x ="", y = "Haeufigkeit")+ scale_x_discrete(labels = c("Nein", "Ja")) + ylim(c(0,1000))

ggplot(data.frame(table_ohne_zh), aes(x = Var1, y = Freq)) + geom_bar(stat = "identity") + geom_text(label = table_ohne_zh, vjust = -1) + labs(title="Ohne Zentralheizung", x =" ", y = "Haeufigkeit") + scale_x_discrete(labels = c("Nein", "Ja")) + ylim(c(0,950))

ggplot(data.frame(table_ohne_badkach), aes(x = Var1, y = Freq)) + geom_bar(stat = "identity") + geom_text(label = table_ohne_badkach, vjust = -1) + labs(title="Gekacheltes Badezimmer", x ="", y = "Haeufigkeit") + scale_x_discrete(labels = c("Nein", "Ja")) + ylim(c(0,850))

ggplot(data.frame(table_badextra), aes(x = Var1, y = Freq)) + geom_bar(stat = "identity") + geom_text(label = table_badextra, vjust = -1) + labs(title="Besondere Zusatzausstattung", x ="", y = "Haeufigkeit") + scale_x_discrete(labels = c("Nein", "Ja")) + ylim(c(0,920))

ggplot(data.frame(table_kueche), aes(x = Var1, y = Freq)) + geom_bar(stat = "identity") + geom_text(label = table_kueche, vjust = -1) + labs(title="Gehobene Kueche", x ="", y = "Haeufigkeit") + scale_x_discrete(labels = c("Nein", "Ja")) + ylim(c(0, 950))




# bivariat
t_cor <- function(x, n) x * sqrt(n-2) / sqrt(1 - x^2)
t_test <- function(x, alpha = 0.05) {
        if(1-pt(abs(x),999) < alpha / 2){
			return(TRUE)
        } else {
			return(FALSE)
		}
}

names(miete)
cor_miete <- cor(cbind(miete$Nettomiete, miete$Wohnflaeche, miete$Zimmeranzahl, as.numeric(miete$Alter_Gruppiert), as.numeric(miete$Wohnanlage), miete$Ohne_Warmwasservers, miete$Ohne_Zentralheizung, miete$Ohne_Gekacheltes_Bad, miete$Extra_Badausst, miete$Gehobene_Kueche))

names(miete)
dim(cor_miete)
ncol(miete)
cor_cp <- cor_miete
cor_cp[row(cor_cp) < col(cor_cp)] <- NA         
colnames(cor_cp) <- names(miete)
rownames(cor_cp) <- names(miete)
diag(cor_cp) <- 1

# Werte <- as.numeric(cor_miete)
Werte <- melt(cor_cp, na.rm = TRUE)
Werte$value <- round(Werte$value, 1) 

ggplot(Werte, aes(Var1, Var2, fill = value)) + geom_tile(colour = "white") + labs(title="Korrelationsmatrix Gesamt", x ="", y = "") + scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, limit = c(-1,1), space = "Lab",name="Pearson\nCorrelation") + scale_x_discrete(guide = guide_axis(angle = 45)) + geom_text(aes(Var1, Var2, label = value), color = "black", size = 4) + theme(legend.position = "none")

# signifikant
cor_matr_t_werte <- apply(cor_miete, 2, t_cor, n = nrow(miete))
diag(cor_matr_t_werte) <- 0
res <- matrix(0, ncol = ncol(cor_miete), nrow = nrow(cor_miete))

for(i in 1:(nrow(cor_matr_t_werte)-1)){
	for(j in 1:nrow(cor_matr_t_werte)){
		if(t_test(cor_matr_t_werte[i,j], alpha = 0.01)){
			res[i,j] <- cor_miete[i,j]
		}
	}
}

res[row(res) < col(res)] <- NA         
colnames(res) <- names(miete)
rownames(res) <- names(miete)
diag(res) <- 1

# Werte <- as.numeric(cor_miete)
Werte <- melt(res, na.rm = TRUE)
Werte$value <- round(Werte$value, 1) 

ggplot(Werte, aes(Var1, Var2, fill = value)) + geom_tile(colour = "white") + labs(title="Korrelationsmatrix Signifikant", x ="", y = "") + scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, limit = c(-1,1), space = "Lab",name="Pearson\nCorrelation") + scale_x_discrete(guide = guide_axis(angle = 45)) + geom_text(aes(Var1, Var2, label = value), color = "black", size = 4) + theme(legend.position = "none")

# berechnung mgl multico
X <- cbind(miete$Nettomiete, miete$Wohnflaeche, miete$Zimmeranzahl, as.numeric(miete$Alter_Gruppiert), as.numeric(miete$Wohnanlage), miete$Ohne_Warmwasservers, miete$Ohne_Zentralheizung, miete$Ohne_Gekacheltes_Bad, miete$Extra_Badausst, miete$Gehobene_Kueche)

df_X <- data.frame(miete$Nettomiete, miete$Wohnflaeche, miete$Zimmeranzahl, as.numeric(miete$Alter_Gruppiert), as.numeric(miete$Wohnanlage), miete$Ohne_Warmwasservers, miete$Ohne_Zentralheizung, miete$Ohne_Gekacheltes_Bad, miete$Extra_Badausst, miete$Gehobene_Kueche)

# det == 0?
det(t(X) %*% X)

# vif
for(i in 2:ncol(df_X)){
  if(1/(1-summary(lm(df_X[,i] ~ ., df_X[,-c(1,i)]))$r.squared) > 5) print(paste("Vif groesser als 5 fuer",i))
}
# keine multicolinearitaet


# wohnflaeche
ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete)) + geom_point() + geom_smooth(method = "lm") + labs(title="Preis / Wohnflaeche", x ="Wohnflaeche", y = "Preis")

names(miete)

# Alter
ggplot(miete, aes(y = Nettomiete, x = Alter_Gruppiert)) + geom_boxplot() + geom_smooth(method = "loess", se=TRUE, aes(group=1)) 

# Zimmer
ggplot(miete, aes(x = as.factor(rooms), y = nm)) + geom_boxplot() + geom_smooth(method = "lm", se=TRUE, aes(group=1)) + labs(title="Preis / Zimmer", x ="Zimmer", y = "Preis")

# binaeren 
ggplot(miete, aes(x = as.factor(wohngut), y = nm)) + geom_boxplot() + labs(title="Preis / Gute Wohnanlage", x ="", y = "Preis") + scale_x_discrete(labels = c("Nein", "Ja"))

# beste wohnanlage
ggplot(miete, aes(x = as.factor(wohnbest), y = nm)) + geom_boxplot() + labs(title="Preis / Beste Wohnanlage", x ="", y = "Preis") + scale_x_discrete(labels = c("Nein", "Ja"))

# warmwasser
ggplot(miete, aes(x = as.factor(ww0), y = nm)) + geom_boxplot() + labs(title="Preis / Warmwasser Vorhanden", x ="", y = "Preis") + scale_x_discrete(labels = c("Ja", "Nein"))

# zentralheizung
ggplot(miete, aes(x = as.factor(zh0), y = nm)) + geom_boxplot() + labs(title="Preis / Zentralheizung Vorhanden", x ="", y = "Preis") + scale_x_discrete(labels = c("Ja", "Nein"))

# gekacheltes badezimmer
ggplot(miete, aes(x = as.factor(badkach0), y = nm)) + geom_boxplot() + labs(title="Preis / Gekacheltes Badezimmer", x ="", y = "Preis") + scale_x_discrete(labels = c("Ja", "Nein"))

# badezimmer extraausstattung
ggplot(miete, aes(x = as.factor(badextra), y = nm)) + geom_boxplot() + labs(title="Preis / Badezimmer Extraausstattung", x ="", y = "Preis") + scale_x_discrete(labels = c("Nein", "Ja"))

# gehobene kueche
ggplot(miete, aes(x = as.factor(kueche), y = nm)) + geom_boxplot() + labs(title="Preis / Gehobene Kueche", x ="", y = "Preis") + scale_x_discrete(labels = c("Nein", "Ja"))

names(miete)

# Trivariate Analysen
## Wohnflaeche
# ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color= as.factor(Zimmeranzahl))) + geom_point()  + labs(title="Preis / Wohnflaeche", x ="Wohnflaeche", y = "Preis")
ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color= as.factor(Zimmeranzahl))) + geom_smooth(method = "lm", alpha = 0.1 ) + labs(title="Nettomiete / Wohnflaeche und Zimmeranzahl", x ="Wohnflaeche", y = "Nettomiete", color = "Zimmeranzahl") + theme(legend.position = "bottom")
lm1 <- lm(Nettomiete ~ Wohnflaeche * as.factor(Zimmeranzahl), data = miete)
summary(lm1)

ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color = Alter_Gruppiert)) + geom_smooth(method = "lm", alpha = 0.1) + labs(title="Nettomiete / Wohnflaeche und Alter_Gruppiert", x ="Wohnflaeche", y = "Nettomiete", color = "Alter_Gruppiert") + theme(legend.position = "bottom")
lm2 <- lm(Nettomiete ~ Wohnflaeche * Alter_Gruppiert, data = miete)
summary(lm2)
#alle interaktionen hochsignifikant

ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color = Wohnanlage)) +  geom_smooth(method = "lm") + labs(title="Nettomiete / Wohnflaeche und Wohnanlage", x ="Wohnflaeche", y = "Nettomiete", color = "Wohnanlage") + theme(legend.position = "bottom")
lm3 <- lm(Nettomiete ~ Wohnflaeche * Wohnanlage, data = miete)
summary(lm3)

ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color = as.factor(Ohne_Warmwasservers))) + geom_smooth(method = "lm") + labs(title="Nettomiete / Wohnflaeche und Ohne Warmwasserversorgung", x ="Wohnflaeche", y = "Nettomiete", color = "Ohne Warmwasserversorgung") + theme(legend.position = "bottom")
lm4 <- lm(Nettomiete ~ Wohnflaeche * as.factor(Ohne_Warmwasservers), data = miete)
summary(lm4)

# gleich wie davor
ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color = as.factor(Ohne_Zentralheizung))) + geom_smooth(method = "lm", size = 3) + labs(title="Nettomiete / Wohnflaeche und Ohne Zentralheizung", x ="Wohnflaeche", y = "Nettomiete", color = "Ohne Zentralheizung") + theme(legend.position = "bottom")
lm5 <- lm(Nettomiete ~ Wohnflaeche * as.factor(Ohne_Zentralheizung), data = miete)
summary(lm5)

# nicht signifikant
ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color = as.factor(Ohne_Gekacheltes_Bad))) +  geom_smooth(method = "lm", size = 3) + labs(title="Nettomiete / Wohnflaeche und Ohne Zentralheizung", x ="Wohnflaeche", y = "Nettomiete", color = "Ohne Zentralheizung") + theme(legend.position = "bottom")
lm6 <- lm(Nettomiete ~ Wohnflaeche * as.factor(Ohne_Gekacheltes_Bad), data = miete)
summary(lm6)

table(miete_alt$Zentralheizung)
table(miete$Ohne_Zentralheizung)


# nicht signifikant
ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color = as.factor(Extra_Badausst))) + geom_smooth(method = "lm", size = 3) + labs(title="Preis / Wohnflaeche", x ="Wohnflaeche", y = "Preis")
lm7 <- lm(Nettomiete ~ Wohnflaeche * as.factor(Extra_Badausst), data = miete)
summary(lm7)

# signifikant
ggplot(miete, aes(x = Wohnflaeche, y = Nettomiete, color = as.factor(Gehobene_Kueche))) + geom_smooth(method = "lm") + labs(title="Nettomiete / Wohnflaeche und Gehobene Kueche", x ="Wohnflaeche", y = "Nettomiete", color = "Gehobene Kueche") + theme(legend.position = "bottom")
lm8 <- lm(Nettomiete ~ Wohnflaeche * as.factor(Gehobene_Kueche), data = miete)
summary(lm8)


# nicht signifikant
ggplot(miete, aes(y = Nettomiete, x = Alter_Gruppiert, fill = Wohnanlage)) + geom_boxplot()
lm9 <- lm(Nettomiete ~ Alter_Gruppiert * Wohnanlage, data = miete)
summary(lm9)


# auf jeden fall sehr interessant
ggplot(miete, aes(y = Nettomiete, x = Alter_Gruppiert, fill = as.factor(Zimmeranzahl))) + geom_boxplot() + labs(title="Nettomiete / Alter_Gruppiert und 
Zimmeranzahl", x ="Alter", y = "Nettomiete", fill = "Zimmeranzahl") + theme(legend.position = "bottom")
lm10 <- lm(Nettomiete ~ Alter_Gruppiert * as.factor(Zimmeranzahl), data = miete)
summary(lm10)

# nichts signifikant
ggplot(miete, aes(y = Nettomiete, x = Alter_Gruppiert, fill = as.factor(Ohne_Warmwasservers))) + geom_boxplot()
lm11 <- lm(Nettomiete ~ Alter_Gruppiert * as.factor(Ohne_Warmwasservers), data = miete)
summary(lm11)


# nichts signifikant
ggplot(miete, aes(y = Nettomiete, x = Alter_Gruppiert, fill = as.factor(Ohne_Zentralheizung))) + geom_boxplot()
lm12 <- lm(Nettomiete ~ Alter_Gruppiert * as.factor(Ohne_Zentralheizung), data = miete)
summary(lm12)

# ganz schwach nur signifikant, nicht wirklich interessant
ggplot(miete, aes(y = Nettomiete, x = Alter_Gruppiert, fill = as.factor(Extra_Badausst))) + geom_boxplot()
lm13 <- lm(Nettomiete ~ Alter_Gruppiert * as.factor(Extra_Badausst), data = miete)
summary(lm13)

# beobachte den unterschie zwischen mit und ohne. die gehobene Kueche "stabilisiert" den preis in den verschiedenen kategorien. ohne sehen wir das "U" muster
ggplot(miete, aes(y = Nettomiete, x = Alter_Gruppiert, fill = as.factor(Gehobene_Kueche))) + geom_boxplot() + labs(title="Nettomiete / Alter_Gruppiert und 
Gehobene Kueche", x ="Alter", y = "Nettomiete", fill = "Gehobene Kueche") + theme(legend.position = "bottom")
lm14 <- lm(Nettomiete ~ Alter_Gruppiert * as.factor(Gehobene_Kueche), data = miete)
summary(lm14)



# nichts signifikant
ggplot(miete, aes(y = Nettomiete, x = Wohnanlage, fill = as.factor(Ohne_Warmwasservers))) + geom_boxplot()
lm15 <- lm(Nettomiete ~ Wohnanlage * as.factor(Ohne_Warmwasservers), data = miete)
summary(lm15)

# nichts signifikant
ggplot(miete, aes(y = Nettomiete, x = Wohnanlage, fill = as.factor(Ohne_Zentralheizung))) + geom_boxplot()
lm16 <- lm(Nettomiete ~ Wohnanlage * as.factor(Ohne_Zentralheizung), data = miete)
summary(lm16)

# definitiv interessant. wohnungen in bester lage weisen einen deutlichen unterschied im preis aus bei mit oder ohne extra badausstattung
ggplot(miete, aes(y = Nettomiete, x = Wohnanlage, fill = as.factor(Extra_Badausst))) + geom_boxplot() + labs(title="Nettomiete / Wohnanlage und 
Extra Badausstattung", x ="Wohnanlage", y = "Nettomiete", fill = "Extra_Badausst") + theme(legend.position = "bottom")
lm17 <- lm(Nettomiete ~ Wohnanlage * as.factor(Extra_Badausst), data = miete)
summary(lm17)

# nicht signifikant
ggplot(miete, aes(y = Nettomiete, x = Wohnanlage, fill = as.factor(Gehobene_Kueche))) + geom_boxplot()
lm18 <- lm(Nettomiete ~ Wohnanlage * as.factor(Gehobene_Kueche), data = miete)
summary(lm18)


# nicht signifikant
ggplot(miete, aes(y = Nettomiete, x = as.factor(Ohne_Warmwasservers), fill = as.factor(Ohne_Zentralheizung))) + geom_boxplot()
lm19 <- lm(Nettomiete ~ as.factor(Ohne_Warmwasservers) * as.factor(Ohne_Zentralheizung), data = miete)
summary(lm19)

# nicht signifikant
ggplot(miete, aes(y = Nettomiete, x = as.factor(Ohne_Warmwasservers), fill = as.factor(Extra_Badausst))) + geom_boxplot()
lm20 <- lm(Nettomiete ~ as.factor(Ohne_Warmwasservers) * as.factor(Extra_Badausst), data = miete)
summary(lm20)

# nicht genug daten
ggplot(miete, aes(y = Nettomiete, x = as.factor(Ohne_Warmwasservers), fill = as.factor(Gehobene_Kueche))) + geom_boxplot()
lm21 <- lm(Nettomiete ~ as.factor(Ohne_Warmwasservers) * as.factor(Gehobene_Kueche), data = miete)
summary(lm21)


# nicht signifikant
ggplot(miete, aes(y = Nettomiete, x = as.factor(Ohne_Zentralheizung), fill = as.factor(Extra_Badausst))) + geom_boxplot()
lm22 <- lm(Nettomiete ~ as.factor(Ohne_Zentralheizung) * as.factor(Extra_Badausst), data = miete)
summary(lm22)

# nicht genug beobachtungen
ggplot(miete, aes(y = Nettomiete, x = as.factor(Ohne_Zentralheizung), fill = as.factor(Gehobene_Kueche))) + geom_boxplot()
lm23 <- lm(Nettomiete ~ as.factor(Ohne_Zentralheizung) * as.factor(Gehobene_Kueche), data = miete)
summary(lm23)


# decision tree
tree <- rpart(Nettomiete ~ ., data = miete, method = "anova", control=list(cp = 0.005))
rpart.plot(tree)


tree_fitted <- predict(tree, miete[,-1])
tree_residuals <- miete$Nettomiete - tree_fitted
plot(tree_residuals ~ tree_fitted)


names(miete)
# Modell GLS vs LM Pre Analysis




names(miete)

# Modellselektion mittels best subset selection


# excludiere zimmeranzahl
miete_neu <- miete[,-3]

n_var <- ncol(miete_neu)-1
# save results
res <- list()


for(i in 1:n_var){

    # combn returns a matrix with all possoble permutations of a given object
    # this will serve to select all possible models for each "level" i
    select <- t(combn(1:i, m = i)+1)

    # number of models for each level
    n  <- nrow(select)

    # init temp variable for later use
    temp  <- Inf

    # for each permutation
    for(j in 1:n){
        # calculate the model
        # model  <- glm(as.formula(paste("fraud_reported ~", paste(rownames(sig)[select[j,]], collapse = "+"))),family = "binomial", data = fraud)
        model  <- lm(formula(paste(names(miete_neu)[1], " ~ ", paste(names(miete_neu)[select[j,]], collapse = "+"))),data = miete_neu)

        # select the model with the smallest SSR at each level
        if(sum(residuals(model)^2) < temp){

            # new smalles value
            temp  <- sum(residuals(model)^2)

            # store model
            res[[i]]  <- list(
                Variables = paste(names(miete_neu)[select[j,]]),  
                SSR = sum(residuals(model)^2), 
                Mod = model,
                NumVariables = i)
        }
    }    
}

res

mallows_cp <- function(model){
    n <- length(model$residuals)
    p <- length(model$coefficients)
    trng_rss <- mean(model$residuals^2)
    sigma_hat <- sum(model$residuals^2) / (n-p)
    korrekturfaktor <- (2/n) * sigma_hat
    return( trng_rss + korrekturfaktor )  
}

# compare AIC, BIC and Mallow's Cp
modell_selection  <- matrix(0, ncol = 3, nrow = length(res))
colnames(modell_selection)  <- c("AIC", "BIC", "Mallow's Cp")

# vergleiche resultate
i <- 1
for(elem in res){
    modell_selection[i, 1]  <- AIC(elem$Mod) 
    modell_selection[i, 2]  <- BIC(elem$Mod)
    modell_selection[i, 3]  <- mallows_cp(elem$Mod) 
    i <- i + 1
}

# get rowindex of smellest value in each column
best_model_mod_selection  <- apply(modell_selection, 2, function(x){which(x == min(x))})
best_model_mod_selection

# beste subset modell
best_model <- res[[best_model_mod_selection[1]]]$Mod
sum_best_model <- summary(best_model)

 
# lm interaktionen
sum_lminter <- summary(lsinter <-lm(Nettomiete ~  Wohnflaeche * Wohnanlage + Wohnflaeche *Alter_Gruppiert +  Wohnflaeche *Ohne_Zentralheizung + Wohnflaeche * Gehobene_Kueche +  Alter_Gruppiert * Gehobene_Kueche + Wohnanlage *Extra_Badausst + Ohne_Warmwasservers + Ohne_Gekacheltes_Bad , data = miete))

sig_model_het <- coeftest(lsinter, vcovHC(lsinter, "HC0"))
sig_model_het_sig <- which(sig_model_het[, 4] < 0.05)
sig_model <- round(sig_model_het[sig_model_het_sig, ], digits = 3)


# inter minimiert
sum_lminter_sig <- summary(lsinter_sig <-lm(Nettomiete ~  Wohnflaeche *Alter_Gruppiert +  Alter_Gruppiert * Gehobene_Kueche + Ohne_Zentralheizung + Gehobene_Kueche + Extra_Badausst + Ohne_Warmwasservers + Ohne_Gekacheltes_Bad , data = miete))

sum_lminter_sig_het <- coeftest(lsinter_sig, vcovHC(lsinter_sig, "HC0"))
sum_lminter_sig_het_sig <- which(sum_lminter_sig_het[, 4] < 0.05)
sum_lminter_sig <- round(sum_lminter_sig_het[sum_lminter_sig_het_sig, ], digits = 3)


# Modell Evaluierung
Rsq <- c(sum_best_model$adj.r.squared, sum_lminter$adj.r.squared, sum_lminter_sig$adj.r.squared, sum_lminter_sig_alter$adj.r.squared)
AIC_mod <- c(AIC(best_model), AIC(lsinter), AIC(lsinter_sig), AIC(lsinter_sig_alter))
BIC_mod <- c(BIC(best_model), BIC(lsinter), BIC(lsinter_sig), BIC(lsinter_sig_alter))
mod_comp <- data.frame(AdjRsq = Rsq, AIC = AIC_mod, BIC = BIC_mod)
rownames(mod_comp) <- c("Keine Interakt.", "Interakt.", "SigInterakt.")
mod_comp










# Verletztung der linearitaetsannahme / homoscedastizitaet
test_lin <- data.frame(Residuen = lsinter_sig$residuals, Fitted = lsinter_sig$fitted.values)
ggplot(test_lin, aes(x = Fitted, y = Residuen)) + geom_point() + labs(title="Residuen vs Prognose", x ="Prognose", y = "Residuen")

# formaler test
# library(nlme)
bptest(best_model)$p.value < 0.05

# heteroskedastische modell
wt <- 1 / lm(abs(lsinter_sig$residuals) ~ lsinter_sig$fitted.values)$fitted.values^2
wls <- lm(Nettomiete ~  Wohnflaeche * Wohnanlage + Wohnflaeche *Alter_Gruppiert +  Alter_Gruppiert * Gehobene_Kueche + Ohne_Zentralheizung + Gehobene_Kueche + Extra_Badausst + Ohne_Warmwasservers + Ohne_Gekacheltes_Bad , data = miete, weights = wt)

ggplot(data.frame(x = wls$fitted.values, y = wls$residuals), aes(x=x, y=y)) + geom_point() + labs(title="Residuen vs Prognose Gewichtet", x ="Prognose", y = "Residuen")

mean(wls$residuals^2)
mean(lsinter_sig$residuals^2)



sum_table <- round(coeftest(mod_1, vcovHC(mod_1, "HC0"))[1:13,], 5)
sum_table[1,1]
summary(mod_1)
plot(fitted(miete.gls), residuals(miete.gls))


# Ausreisser
cdist <- cooks.distance(best_model)
ausreisser <- unique(which(cdist > 4 * mean(cdist)))
best_mod_kein_ausreisser <- lm(Nettomiete ~  ., data = miete[-ausreisser,-3])

test_best_mod_kein_ausreisser <- data.frame(Residuen = best_mod_kein_ausreisser$residuals, Fitted = best_mod_kein_ausreisser$fitted.values)
ggplot(test_best_mod_kein_ausreisser, aes(x = Fitted, y = Residuen)) + geom_point()

ausreisser_vgl <- data.frame(Ohne_Ausreisser = round(best_mod_kein_ausreisser$coefficients,2), Mit_Ausreisser = round(best_model$coefficients,2))
ausr <- melt(cbind(X = rownames(ausreisser_vgl), ausreisser_vgl))

ggplot(ausr, aes(x = X, y= value, fill = variable)) + geom_bar(stat = 'identity', position = "dodge") +
  scale_x_discrete(guide = guide_axis(angle = 45)) + labs(title="Modellvergleich mit und ohne Ausreisser", x ="Variable", y = "Wert")


# formaler test
library(lmtest)
bptest(best_mod_kein_ausreisser)

ggplot(best_mod_kein_ausreisser, aes(sample = rstandard(best_mod_kein_ausreisser))) + stat_qq() + stat_qq_line()

shapiro.test(best_mod_kein_ausreisser$residuals)








 













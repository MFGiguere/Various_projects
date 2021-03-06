#import all necessary files and the official qc datas for covid
library(tidyverse)
library(scales)
library(zoo)
library(dplyr)
df <- read.csv('https://msss.gouv.qc.ca/professionnels/statistiques/documents/covid19/COVID19_Qc_RapportINSPQ_HistoVigie.csv', header=TRUE, fileEncoding="UTF-8-BOM")


#filter some datas to make it easier to work with
df2 <- df %>%
  filter(Date!="Date inconnue") %>%
  mutate(Date=as.Date(Date)) %>%
  rename(Autre = Nb_Deces_Cumulatif_Autre, Chsld=Nb_Deces_Cumulatif_CHCHSLD, Domicile=Nb_Deces_Cumulatif_DomInc, RPA=Nb_Deces_Cumulatif_RPA) %>%
  gather(key='Lieu', value='D�c�s', 6:9)


#Cumulative number of deaths split by location
p1 <- ggplot(data=df2, mapping = aes(x=Date, y =D�c�s), group=Lieu) +
  geom_line(aes(color=Lieu), size=1.5) +
  labs(x = "Du 23 janvier 2020 � aujourd'hui", y = "D�c�s", 
       title = "D�c�s cumulatifs li�s au covid au Qu�bec par emplacement")  +
  scale_y_continuous(labels = comma)
p1 + theme_dark() #using theme dark because it's easier to read!


#Graph to plot 2 linear model, one for cumulative death and one for cumulative cases
ggplot(data = df2) +
  geom_line(mapping = aes(x=Date, y=Nb_Cas_Cumulatif, color='Cas'), size=1.5) +
  geom_line(mapping = aes(x=Date, y=Nb_Deces_Cumulatif_Total*50, color='D�c�s'), size=1.5)+
  labs(x = "Du 23 janvier 2020 � aujourd'hui", y = "Cas cumulatifs", 
     title = "�volution cumulative des cas et d�c�s de covid au Qu�bec")  +
  scale_y_continuous(labels = comma,
  sec.axis = sec_axis(~ . / 50, name = "D�c�s cumulatifs", labels = comma)) +
  scale_color_manual(name='Type de\ndonn�e', values=c('black', 'red'))

#graph to plot 2 linear model, one for new cases and one for new deaths
ggplot(data=df2, mapping = aes(x=Date)) +
  geom_line(mapping = aes(y=Nb_Nvx_Cas, color='Cas')) +
  geom_line(mapping = aes(y=Nb_Nvx_Deces_Total*100, color='D�c�s')) +
  labs(x = "Du 23 janvier 2020 � aujourd'hui", y = "Nouveaux cas", 
       title = "�volution des cas de covid au Qu�bec")  +
  scale_y_continuous(labels = comma, 
  sec.axis = sec_axis(~ . / 100, name = "Nouveaux d�c�s", labels = comma)) +
  scale_color_manual(name='Type de\ndonn�e', values=c('black', 'red'))

library(tidyverse)
library(ggpubr)
library(ggplot2)
library(grid)


#1. Getting the data 
#First, you need to download your archive
#See here: https://support.strava.com/hc/en-us/articles/216918437-Exporting-your-Data-and-Bulk-Export#:~:text=Choose%20%22Settings%2C%22%20then%20find,may%20take%20a%20few%20hours.)
zipfile = "C:/Users/your_name/Downloads/export_12345678.zip" #Add location to the file. 
df <- read.csv(unz(zipfile, "activities.csv")) #This read the activity file


#2. Data modification
#This will do some modification on the file and create a data subset focused on triathlon.
df_cleaned <- df %>%
  mutate(Date = as.Date(lubridate::mdy_hms(Activity.Date)),
         Activity = str_replace_all(Activity.Type, "Virtual ", ""), #Replace virtual ride/run by standard. 
         Activity = fct_lump_min(Activity, 25), #Groups in other all activities done less than 25 times. 
         Distance = (str_replace(Distance, ",", ".")),
         Distance = case_when 
         (nchar(Distance) == 3 ~ strtoi(Distance)/1000,  #Reformat swim because swim it is in a different format. 
           TRUE ~ as.numeric(Distance)),
         Time = Elapsed.Time/(60*60), #Convert time in hours from seconds
         Speed = Distance/Time, 
         month = lubridate::floor_date(Date, 'month')
         ) %>%
  group_by(month, Activity) %>%
  subset(select=c(month, Activity, Distance, Time, Speed))
df_tri <- subset(df_cleaned, Activity=="Run" | Activity=="Swim"|Activity=="Ride")
df_run <- subset(df_cleaned, Activity=="Run")

#3. Aesthetics
#This create a base graph
base_graph <- ggplot(data=df_cleaned, mapping = aes(x=month, fill=Activity)) +
  theme_minimal(base_size=9) +
  theme(axis.line = element_line(linewidth = 1), plot.title = element_text(hjust = 0.5), 
        plot.margin = unit(c(0, 0.2, -0.5, 0.5), "lines",), axis.title.y = element_text(angle = 0,vjust = 0.5))+
  xlab("") + 
  ylab("") +
  scale_x_date(date_breaks = "4 month", minor_breaks="1 month", date_labels = "%b\n%Y", 
               limits=as.Date(c("2020-03-01", "2023-04-01")), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_fill_manual(values = c("indianred3", "chartreuse3", "cyan3", "lightsalmon3", "antiquewhite3"), 
                    name = "Type d'activité",
                    labels=c("Vélo", "Course", "Nage", "Musculation", "Autre")) 


#4. Plot data part 1
#This create 4 plots for 4 interesting y value.
nb_graph <- base_graph + geom_bar() + ggtitle("Quantité") + ylab("#")
time_graph <- base_graph + geom_col(mapping=aes(y=Time)) + ggtitle("Durée")  + ylab("h")
km_graph <- base_graph + geom_col(mapping=aes(y=Distance)) + ggtitle("Distance") + ylab("k\nm")
spd_graph <- base_graph + stat_summary(mapping=aes(y=Speed), geom="col",fun=mean) + 
  ggtitle("Vitesse") + ylab("k\nm\n/\nh")

#I end up using only 2 value, mostly because 'speed and 'distance' is irrelevant for most of my
#other activities and for weight training. 
plot <- ggarrange(nb_graph, time_graph, nrow=2, ncol=1, 
                  common.legend = TRUE, legend="bottom")
annotate_figure(plot, top = text_grob("Les activités sportives cumulées de Maxime", hjust=0.5, face="bold", size=16))

#I still plot run speed separatly
spd_graph <- base_graph + stat_summary(data=df_run, mapping=aes(y=Speed, colour=Activity), linewidth=1.5, geom="line",fun=mean) +
  geom_smooth(data=df_run, mapping=aes(y=Speed, colour=Activity), linetype="dashed", fill = "NA") +
  ggtitle("Vitesse") + ylab("k\nm\n/\nh") + scale_colour_manual(values = c("chartreuse3"), 
                                                              name = "Type d'activitÃ©",
                                                              labels=c("Course"))  
ggarrange(spd_graph, nrow=2, ncol=1, 
          common.legend = TRUE, legend="bottom")
annotate_figure(spd_graph, top = text_grob("Les activitÃ©s sportives de Maxime", hjust=0.5, face="bold", size=16))


#5. Plot data part 2
#This is the base to plot a facet element. 
facet_graph <- base_graph + theme(strip.background = element_blank(), strip.text = element_blank()) +
  scale_y_continuous(labels=scales::number_format(accuracy=1), n.breaks=4, expand = c(0, 0)) + 
  facet_grid(vars(Activity[Activity=="Run" | Activity=="Swim"|Activity=="Ride"]), scales="free_y") 

#This creates the 4 facets. The structure is similar to part 1. 
nb_graph2 <- facet_graph + geom_area(data=df_tri, stat="count") + ggtitle("Quantité") + ylab("#")
time_graph2 <- facet_graph + stat_summary(data=df_tri, mapping=aes(y=Time), geom="area", fun=sum) + 
  ggtitle("Durée")  + ylab("h")
km_graph2 <- facet_graph + stat_summary(data=df_tri, mapping=aes(y=Distance), geom="area", fun=sum) + 
  ggtitle("Distance") + ylab("k\nm")
spd_graph2 <- facet_graph + stat_summary(data=df_tri, mapping=aes(y=Speed), geom="area",fun=mean) + 
  ggtitle("Vitesse") + ylab("k\nm\n/\nh")


#Plotting the result
plot <- ggarrange(nb_graph2, time_graph2, km_graph2, spd_graph2, nrow=2, ncol=2, 
                  common.legend = TRUE, legend="bottom")
annotate_figure(plot, top = text_grob("Les activités sportives de Maxime", hjust=0.5, face="bold", size=16))


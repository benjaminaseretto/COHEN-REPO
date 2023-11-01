if (!require(readr)) {
  install.packages("readr")
}
library(readr)

# Carga el archivo CSV
df <- read_csv("C:\\Users\\Benja\\Downloads\\haunted_places.csv")

# Muestra las dos primeras filas del DataFrame
head(df, 2)
# Obtiene los 5 valores más comunes para la columna "city"
top_city <- head(sort(table(df$city), decreasing = TRUE), 5)

# Obtiene los 5 valores más comunes para la columna "state"
top_state <- head(sort(table(df$state), decreasing = TRUE), 5)

# Muestra los resultados
top_city
top_state

# Carga las librerías necesarias si aún no están instaladas
if (!require(dplyr)) {
  install.packages("dplyr")
}
if (!require(VIM)) {
  install.packages("VIM")
}
library(dplyr)
library(VIM)


columns_to_impute <- c("state_abbrev", "longitude", "latitude", "city_longitude", "city_latitude")
# Instala el paquete 'mice' si aún no lo has hecho
install.packages('mice')

# Carga el paquete 'mice'
library(mice)

# Aplica la imputación K-NN a las columnas seleccionadas
imp <- mice(df[columns_to_impute], method='pmm', m=5)

# Obtiene los datos completos
complete_data <- complete(imp)

# Carga las bibliotecas necesarias
library(stringr)
library(dplyr)

# Concatena todas las descripciones en un solo texto
all_descriptions <- paste(df$description, collapse = " ")

# Divide el texto en oraciones
sentences <- str_split(all_descriptions, pattern = fixed(". "))

# Convierte la lista de oraciones en un data frame
sentences_df <- data.frame(table(unlist(sentences)))

# Ordena las oraciones por su frecuencia
sentences_df <- arrange(sentences_df, desc(Freq))

# Imprime las 10 oraciones más comunes
head(sentences_df, 10)

write.csv(df, file = "C:\\Users\\Benja\\Downloads\\haunted_places_imputado.csv", row.names = FALSE)

install.packages('RPostgreSQL')


# Cargar la biblioteca necesaria
library(RPostgreSQL)

# Create a PostgreSQL driver
drv <- dbDriver("PostgreSQL")

# Establish the connection
con <- dbConnect(drv, dbname = "postgres",
                 host = "localhost", port = 5433,
                 user = "postgres", password = "031015")

# Don't forget to clear the connection when you're done
dbDisconnect(con)

# Cerrar la conexión
dbDisconnect(con)








**Artefacto de Prueba Citrus para Recaudos Una Vía - Dynamic RTR**
==============

Este proyecto Java contiene todos los elementos necesarios para llevar a cabo las siguientes pruebas de los servicios Tipo Dynamic RTR con mensajería Estandar:

- Pruebas de Casos Negativos
- Pruebas Modulares
- Pruebas Integrales
- Pruebas de Carga

## **1. Configuración**

### 1.1	Preparación del Artefacto de forma Local

* Descargar de VSTS el repositorio [AW0481_Citrus_MQ_Flat_Project](https://grupobancolombia.visualstudio.com/Vicepresidencia%20Servicios%20de%20Tecnolog%C3%ADa/_git/AW0481_Citrus_MQ_Flat_Project) , el cual contiene el proyecto Java para la ejecución de pruebas.<br>
* Ejecutar el comando <b>mvn install</b> para obtener de Apache Maven todas las librerías necesarias.
* En el archivo <b>citrus-application.properties</b> disponible en la ruta <b>src/test/resources</b> se encuentran las propiedades que se deben modificar para cada servicio a probar.
* Este artefacto deberá ser cargado y versionado en el repositorio Git del servicio Rest de DataPower.


### **1.2. Cargue de Mensajes de Prueba**

Dentro del Directorio **src/resources/templates** están disponibles las siguientes carpetas en las cuales se deberán cargar todos los archivos en extensión .xml a su correspondiente tipo de prueba y con el resultado esperado.

- carga
    - success
- integrales
    - businessException
    - success
    - systemException
- negativos
    - systemException

## **2. Resultados de la Prueba**

Dentro del Directorio **src/resources/results** se guarda un archivo llamado **logReports.log** donde se podrá ver la traza completa de la prueba realizada. 




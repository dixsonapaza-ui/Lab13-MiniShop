# language: es
Requisito: Pruebas de Aceptación del Sistema MiniShop

  Antecedentes:
    Dado que el sistema MiniShop está en funcionamiento
    Y la URL base del servicio es "http://localhost:8080"

  Escenario: CA-01-01 - Listar catálogo con productos registrados
    Dado que existen productos cargados en la base de datos a través de "import.sql"
    Cuando el cliente envía una petición GET a "/api/products"
    Entonces el sistema debe responder con un código de estado HTTP 200
    Y la respuesta debe contener una lista JSON con 10 productos
    Y cada producto debe incluir "id", "name", "price" y "stock"

  Escenario: CA-01-02 - Consultar catálogo vacío (sin productos)
    Dado que no existen productos registrados en el sistema
    Cuando el cliente envía una petición GET a "/api/products"
    Entonces el sistema debe responder con un código de estado HTTP 200
    Y la respuesta debe ser una lista vacía representado por "[]"

  Escenario: CA-02-01 - Consultar detalle de un producto existente
    Dado que existe un producto registrado con ID 1 y nombre "Laptop Asus"
    Cuando el cliente envía una petición GET a "/api/products/1"
    Entonces el sistema debe responder con un código de estado HTTP 200
    Y la respuesta debe contener un objeto JSON con el nombre "Laptop Asus", precio 1200.0 y stock 15

  Escenario: CA-04-01 - Consultar un producto inexistente
    Dado que no existe ningún producto con el ID 999
    Cuando el cliente envía una petición GET a "/api/products/999"
    Entonces el sistema debe responder con un código de estado HTTP 500
    Y la respuesta debe contener un mensaje explicativo indicando que el producto no existe

  Escenario: CA-05-01 - Registrar un nuevo producto con datos válidos
    Dado que los detalles del producto son nombre "Mouse Inalámbrico", precio 35.0 y stock 20
    Cuando el administrador envía una petición POST a "/api/products" con la representación JSON del producto
    Entonces el sistema debe responder con un código de estado HTTP 201
    Y la respuesta debe retornar el producto creado con su ID autogenerado
    Y el catálogo de productos debe incrementarse a 11 elementos

  Escenario: CA-05-02 - Registrar un producto con datos incompletos
    Dado que los detalles del producto tienen el nombre vacío, precio 15.0 y stock 5
    Cuando el administrador envía una petición POST a "/api/products" con el campo de nombre nulo o vacío
    Entonces el sistema debe responder con un código de estado HTTP 500 o fallar la validación
    Y el catálogo de productos debe mantenerse sin cambios

  Escenario: CA-05-03 - Consultar persistencia del producto registrado
    Dado que se ha registrado exitosamente un producto con ID 11
    Cuando el cliente envía una petición GET a "/api/products/11"
    Entonces el sistema debe responder con un código de estado HTTP 200
    Y el cuerpo de la respuesta debe coincidir exactamente con los datos registrados del ID 11

  Escenario: CA-03-01 - Intentar crear un pedido en endpoint de órdenes
    Dado que el sistema no posee un controlador de órdenes implementado
    Cuando el cliente envía una petición POST a "/api/orders" para crear un pedido
    Entonces el sistema debe responder con un código de estado HTTP 404
    Y el estado de la historia de usuario HU-03 debe reportarse como No Implementada

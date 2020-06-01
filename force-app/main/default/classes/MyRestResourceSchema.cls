
@RestResource(urlMapping='/soforce/demorest/schema/*')
global with sharing class MyRestResourceSchema {
    @HttpGet
    global static void doGet() {
        System.debug('MyRestResourceSchema.doGet');
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;
        String resName = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        if (resName == 'customer') {
            StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'MyCustomerRestResourceSchema' LIMIT 1];
            String body = sr.Body.toString();
            resp.addHeader('Content-Type', 'application/json;charset=UTF-8');
            resp.responseBody = Blob.valueOf(body);
        } else {
            resp.statusCode = 404;
            resp.responseBody = Blob.valueOf('The specified customer is not found.');
        }
    }
}

@RestResource(urlMapping='/my_service/customer/*')
global with sharing class MyCustomerRestResource {
    public static final String BaseCustomerURI = '/my_service/customer/';

    global class Address {
        public String addressType; /* shipping, billing */
        public String street;
        public String city;
        public String province;
        public String postCode;
    } 
        
    global class Customer {
        public String id;
        public String name;
        public String phone;
        public String email;

        public Address[] addresses;
    }   


    public static String generateId() {
        Integer len = 18;
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    @HttpGet
    global static void doGet() {
        System.debug('MyCustomerRestResource.doGet');
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String customerId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        // Get partition
        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.MyServiceCache');

        if (sessionPart.contains(customerId)) {
        
            Customer myCustomer = (Customer)sessionPart.get(customerId);
            res.addHeader('Content-Type', 'application/json;charset=UTF-8');
            res.responseBody = Blob.valueOf(JSON.serialize(myCustomer));
        } else {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('The specified customer is not found.');
        }
    }
    

    @HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String customerId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.MyServiceCache');
        sessionPart.remove(customerId);
    }


    
    @HttpPost
    global static Customer doPost() {
        RestRequest req = RestContext.request;
        String jsonString = req.requestBody.toString();
        Customer newCustomer = (Customer)JSON.deserialize(jsonString, Customer.class);
        
        newCustomer.id = generateId();
        
        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.MyServiceCache');
             
        // Add cache value to the partition
        System.debug(newCustomer);
        sessionPart.put(newCustomer.id, newCustomer);

        return newCustomer;
    }
    
}
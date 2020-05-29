@RestResource(urlMapping='/my_service/customer/*/address/*')
global class MyCustomerAddressRestResource {


    public static String getAddressId(String customerId, String addressType) {
        return customerId + addressType;
    }
    
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String customerURI = req.requestURI.substring(MyCustomerRestResource.BaseCustomerURI.length());
        String customerId = customerURI.substring(0, customerURI.indexOf('/'));
        String addressType = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.MyServiceCache');
        MyCustomerRestResource.Customer myCustomer = (MyCustomerRestResource.Customer)sessionPart.get(customerId);
        MyCustomerRestResource.Address myAddr;
        if (myCustomer != null && myCustomer.addresses != null) {
            for (MyCustomerRestResource.Address addr : myCustomer.addresses) {
                if (addr.addressType == addressType) {
                    myAddr = addr; 
                    break;
                }
            }
        }

        if (myAddr != null) {
            res.addHeader('Content-Type', 'application/json;charset=UTF-8');
            res.responseBody = Blob.valueOf(JSON.serialize(myAddr));
        } else {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('The specified address is not found.');            
        }
    }


    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String jsonString = req.requestBody.toString();
        MyCustomerRestResource.Address myAddr = (MyCustomerRestResource.Address)JSON.deserialize(jsonString, MyCustomerRestResource.Address.class);

        String customerURI = req.requestURI.substring(MyCustomerRestResource.BaseCustomerURI.length());
        String customerId = customerURI.substring(0, customerURI.indexOf('/'));

        if (myAddr.addressType != 'shipping' && myAddr.addressType != 'billing') myAddr.addressType = 'shipping';

        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.MyServiceCache');
        MyCustomerRestResource.Customer myCustomer = (MyCustomerRestResource.Customer)sessionPart.get(customerId);
        if (myCustomer != null) {
            if (myCustomer.addresses != null) {
                Boolean isNew = true;
                for (Integer i = 0; i < myCustomer.addresses.size(); i++) {
                    if (myCustomer.addresses[i].addressType == myAddr.addressType) {
                        // Update
                        myCustomer.addresses[i] = myAddr;
                        isNew = false;
                        break;
                    } 
                }
                if (isNew) 
                    myCustomer.addresses.add(myAddr);
            } else {
                myCustomer.addresses = new List<MyCustomerRestResource.Address> { myAddr };
            }
            res.addHeader('Content-Type', 'application/json;charset=UTF-8');
            res.responseBody = Blob.valueOf(JSON.serialize(myAddr));
            sessionPart.put(customerId, myCustomer);
        } else {
            res.statusCode = 405;
            res.responseBody = Blob.valueOf('The specified customer is not found. The Address cannot be added.');
        }
    }

    
    @HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String customerURI = req.requestURI.substring(MyCustomerRestResource.BaseCustomerURI.length());
        String customerId = customerURI.substring(0, customerURI.indexOf('/'));
        String addressType = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

 
        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.MyServiceCache');
        MyCustomerRestResource.Customer myCustomer = (MyCustomerRestResource.Customer)sessionPart.get(customerId);
        if (myCustomer != null && myCustomer.addresses != null) {
            for (Integer i = 0; i < myCustomer.addresses.size(); i++) {
                if (myCustomer.addresses[i].addressType == addressType) {
                    myCustomer.addresses.remove(i);
                    break;
                } 
            }
        }

        sessionPart.put(customerId, myCustomer);
    }


}
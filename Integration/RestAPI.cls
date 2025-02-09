1. Challenge: Rest Api Authentication through Postman.
Solution: 

Sfdc side:
-I created a Connected App under App Manager
-Gave it a Name, Provided email address, Enabled OAuth Setting (under API), Callback URL: https://localhost, Selected Full access, and Perform requests at any time(refresh token, offline_access) under Selected OAuth Scopes
-Once saved, it generated a new Consumer Key and Consumer Secret

Postman side:
-Created a RestAPI Collection, then added a request for RestAPI Authentication
-Method: Post
-Endpoint: https://login.salesforce.com/services/oauth2/token
-Headers: 
      Authorization: Bearer <Security_Token>
      Content-Type: application/x-www-form-urlencoded
-Body:
      Grant_Type: password
      Client_Id
      Client_Secret
      Username
      Password: <passwordSecurityToken>

-Send Request: 
      Status Code 200 Ok, AccessToken, instanceUrl is received back.


2. Create a REST API endpoint to retrieve Account records, returning names and phone numbers.
Solution: 
Based on the request above, I received the Access token, and instanceUrl that I was able to use to complete the second challenge.

Postman side:
-Method: Get
-Endpoint: <InstanceUrl>/services/data/v52.0/sobjects/Account/<AccountId>
-Body: none

-Send Request: 
      Status Code 200 Ok, received details on the Account record passed.


3. Apex REST Endpoint to get the specific Contact
Solution:

Sfdc side:
-Create Apex RestResource Annotated class

@RestResource(urlMapping='/contact/')
global with sharing class ContactAPi {
    @HttpGet
    global static Contact getContact() {
        RestRequest req = RestContext.request;
        String contactId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        return [SELECT Id, Name, Email FROM Contact WHERE Id = :contactId LIMIT 1];
    }
}

Postman side:
-Method: Get
-Endpoint: <instanceUrl>/services/apexrest/contact/<ContactID>
-Headers: 
   Authorization: Bearer <SecurityToken>
   ContentType: application/json


4. Apex REST Endpoint to get the specific Opportunity
Solution:

Sfdc side:
-Create Apex RestResource Annotated class

Postman side:
-Method: Get
-Endpoint: <instanceUrl>/services/apexrest/contact/<ContactID>
-Headers: 
   Authorization: Bearer <SecurityToken>
   ContentType: application/json


@RestResource(urlMapping='/opportunity/')
global with sharing class OpportunityApi {
    @HttpGet
    global static Opportunity getOpportunity(){
        RestRequest req = RestContext.request;
        String oppId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        return [SELECT Id, Name, Amount, StageName, CloseDate, OwnerId, Type, LeadSource FROM Opportunity WHERE Id =:oppId LIMIT 1];
    }
}


5. Call a Public API from Salesforce using Rest API Callouts to generate random jokes.
Solution: 
What did the fish say when it hit the wall?
Dam.


Sfdc side:
-Created Remote Site Setting, and included the Name and Remote Site URL
-Then Created an Apex Rest API Callout to call the public API to fetch random jokes.
-Then Called this class and method name using Anonymous Window in Dev Console.

Note: Api key and URL endpoint can be found on the account of the public API website.

public class JokeAPIService{
 public static void fetchRandomJoke(){
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
           // String apiKey = 'ef3df01b00021fae86fda6a2074a9f40';
            String endPoint = 'https://official-joke-api.appspot.com/random_joke';
            
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode()==200){
            Map<String, Object> jsonResponse = (Map<String, Object>) Json.deserializeUntyped(response.getBody());
            //System.debug('Weather API Response'+ response.getBody());
            
            String setup =(String)jsonResponse.get('setup');
            String punchLine=(String)jsonResponse.get('punchline');
            System.debug('Here is a joke for you: ');
            System.debug('Setup: '+ setup);
            System.debug('PunchLine: '+punchLine);
            
            }else{
              System.debug('Error: HTTP Status Code' + response.getStatusCode());
            }
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
    }
}


6. Call a Public API from Salesforce using Rest API Callouts to generate city weather.
Solution: 

Sfdc side:
-Created Remote Site Setting, and included the Name and Remote Site URL
-Then Created an Apex Rest API Callout to call the public API to fetch city weather.
-Then Called this class and method name, and passed the specific city, using Anonymous Window in Dev Console.

Note: Api key and URL endpoint can be found on the account of the public API website.

public class WeatherAPIService{
 public static void getWeatherForCity(String city){
        try{
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            String apiKey = 'ef3df01b00021fae86fda6a2074a9f40';
            String endPoint = 'http://api.openweathermap.org/data/2.5/forecast?q='
                + city 
                + '&appid='+ apiKey;
            
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            HttpResponse res = http.send(req);
            
            if(res.getStatusCode()==200){
            System.debug('Weather API Response'+ res.getBody());
            }else{
              System.debug('Error: HTTP Status Code' + res.getStatusCode());
            }
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
    }
}


7.Convert A GET Callout into Queueable Apex

Why Use Queueable Apex for Callouts?

1. Asynchronous Execution: Processes heavy workloads or time-intensive operations outside of synchronous execution.
2. Supports Callouts: Queueable Apex supports making HTTP callouts.
3. Chaining Jobs: You can chain another queueable job from within a queueable.

Steps to Implement
1. Create a Queueable Class
Define a class implementing the Queueable interface and make your GET callout inside it.

public class MyQueueableCallout implements Queueable, Database.AllowsCallouts {
    // Class variables (e.g., endpoint URL or parameters)
    private String endpointUrl;

    // Constructor to pass data
    public MyQueueableCallout(String endpointUrl) {
        this.endpointUrl = endpointUrl;
    }

    // Execute method
    public void execute(QueueableContext context) {
        // Create an HTTP request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('GET');

        try {
            // Make the callout
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                // Process the response
                System.debug('Response: ' + response.getBody());
                // Add your logic to process the response (e.g., update records)
            } else {
                System.debug('Error: ' + response.getStatus());
            }
        } catch (Exception e) {
            System.debug('Callout error: ' + e.getMessage());
        }
    }
}

2. Enqueue the Job
Enqueue the job by instantiating the Queueable class and calling System.enqueueJob.

String endpointUrl = 'https://api.example.com/data';
System.enqueueJob(new MyQueueableCallout(endpointUrl));

3. Optional: Chaining Jobs
If you need to run another job after the first, use the System.enqueueJob method within the execute method of the first job.

public void execute(QueueableContext context) {
    // Perform the callout logic...

    // Chain another job
    System.enqueueJob(new AnotherQueueableClass());
}

4. Testing the Queueable Callout
To test the callout in a test class, use the Test.setMock method to simulate the HTTP response.

@IsTest
private class MyQueueableCalloutTest {
    @IsTest
    static void testCallout() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Enqueue the job
        Test.startTest();
        String endpointUrl = 'https://api.example.com/data';
        System.enqueueJob(new MyQueueableCallout(endpointUrl));
        Test.stopTest();

        // Add assertions to verify behavior
    }
}

// Mock HTTP response
public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody('{"key": "value"}');
        return response;
    }
}
Key Points

• Implements Database.AllowsCallouts: Required for making callouts in a Queueable Apex.
• Governor Limits: Each queueable job runs in its own execution context, so the governor limits are reset.
• Chaining Limits: You can chain up to 50 jobs in a single transaction.






10. Create an Apex REST class that handles GET and POST requests to retrieve and create Account records.






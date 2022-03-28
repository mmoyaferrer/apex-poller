public with sharing class CorrectNumberCallback implements PollFinishCallbackI {
    public void execute(Object httpResponse) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new String[] {'mmoyaferrer@gmail.com'});
        mail.setReplyTo('mmoyaferrer@gmail.com');  
        mail.setSenderDisplayName('Manuel Moya');
        mail.setSubject('Found the number!');
        mail.setPlainTextBody('We found the expected number: ' + httpResponse);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
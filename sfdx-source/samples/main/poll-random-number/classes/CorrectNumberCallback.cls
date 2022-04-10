public with sharing class CorrectNumberCallback implements Callable {
    public Object call(String action, Map<String, Object> args) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new List<String>{ 'mmoyaferrer@gmail.com' });
        mail.setReplyTo('mmoyaferrer@gmail.com');
        mail.setSenderDisplayName('Default Name');
        mail.setSubject('Found the number!');
        mail.setPlainTextBody('We found the expected number: ' + args.get('default'));

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

        return null;
    }
}

function Send_email(Destination,Topic,Text,Attachment,mail,password)

    %% Configure mailer 
    setpref('Internet','SMTP_Server','smtp.gmail.com');
    setpref('Internet','E_mail',mail);
    setpref('Internet','SMTP_Username',mail);
    setpref('Internet','SMTP_Password',password);
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');

    %% Send email
    if isempty(Attachment)
        sendmail(Destination,Topic,Text);
    else
        sendmail(Destination,Topic,Text,Attachment);
    end
    
end
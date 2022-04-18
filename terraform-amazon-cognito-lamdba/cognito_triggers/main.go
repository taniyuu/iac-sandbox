package main

import (
	"bytes"
	"context"
	"fmt"
	"text/template"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type MyEvent struct {
	Name string `json:"name"`
}

func HandleRequest(ctx context.Context, event events.CognitoEventUserPoolsCustomMessage) (events.CognitoEventUserPoolsCustomMessage, error) {
	fmt.Printf("%+v", event)
	tpl := template.Must(template.New("mail_body").Parse("Your Code is {{.Code}}."))
	buf := new(bytes.Buffer)
	tpl.Execute(buf, map[string]string{"Code": event.Request.CodeParameter})
	event.Response.EmailMessage = buf.String()
	return event, nil
}

func main() {
	lambda.Start(HandleRequest)
}

/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/spf13/cobra"
	telebot "gopkg.in/telebot.v3"
)

var (
	// TeleToken bot
	TeleToken = os.Getenv("TELE_TOKEN")
)

const (
	statusURL = "http://34.116.191.131/status"
)

type ObjectStatus struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

func getServiceStatus(serviceName string) (ObjectStatus, error) {
	resp, err := http.Get(statusURL + "/" + serviceName)
	if err != nil {
		return ObjectStatus{}, err
	}
	defer resp.Body.Close()

	// Decode JSON into struct
	var status ObjectStatus
	err = json.NewDecoder(resp.Body).Decode(&status)
	if err != nil {
		return ObjectStatus{}, err
	}

	return status, nil
}

func getStatuses() ([]ObjectStatus, error) {
	resp, err := http.Get(statusURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var serviceList []string
	err = json.NewDecoder(resp.Body).Decode(&serviceList)
	if err != nil {
		return nil, err
	}

	var statuses []ObjectStatus
	for _, serviceName := range serviceList {
		//	var service_cs string
		service_cs := "unknown"

		status, err := getServiceStatus(serviceName)
		if err != nil {
			fmt.Printf("Error retrieving status for %s: %v\n", serviceName, err)
			continue
		} else {
			service_cs = status.Status
		}

		statuses = append(statuses, ObjectStatus{Name: serviceName, Status: service_cs})
	}

	return statuses, nil
}

// docStatusCmd represents the docStatus command
var docStatusCmd = &cobra.Command{
	Use:     "docStatus",
	Aliases: []string{"start"},
	Short:   "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("dokStatus called")

		dok_tele_status, err := telebot.NewBot(telebot.Settings{
			URL:    "",
			Token:  TeleToken,
			Poller: &telebot.LongPoller{Timeout: 10 * time.Second},
		})

		if err != nil {
			log.Fatalf("Plaese check TELE_TOKEN env variable. %s", err)
			return
		}

		dok_tele_status.Handle(telebot.OnText, func(m telebot.Context) error {

			var (
				err error
			)
			log.Print("payload-->"+m.Message().Payload+"<--", "message->"+m.Text()+"<-")
			//payload := m.Message().Payload
			payload := m.Text()

			switch payload {
			case "version":
				err = m.Send(fmt.Sprintf("Hello I'm DOK Status %s!", appVersion))
			case "status":
				statuses, err := getStatuses()
				if err != nil {
					return err
				}

				statusMessage := "Status for monitored objects:\n"
				for _, status := range statuses {
					statusMessage += fmt.Sprintf("%s: %s\n", status.Name, status.Status)
				}

				return m.Send(statusMessage)

			default:
				err = m.Send("Usage: status {service_id}")
			}

			return err

		})

		dok_tele_status.Start()
	},
}

func init() {
	rootCmd.AddCommand(docStatusCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// docStatusCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// docStatusCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

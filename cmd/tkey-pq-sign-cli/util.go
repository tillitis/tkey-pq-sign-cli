// SPDX-FileCopyrightText: 2023 Tillitis AB <tillitis.se>
// SPDX-License-Identifier: BSD-2-Clause

package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/signal"
	"runtime/debug"
	"strings"
	"time"

	"github.com/tillitis/tkeyclient"
	"github.com/tillitis/tkey-pq-device-sign"
)

const (
	// 4 chars each.
	wantFWName0  = "tk1 "
	wantFWName1  = "mkdf"
	wantAppName0 = "tk1 "
	wantAppName1 = "pqsn"
)

func isFirmwareMode(tk *tkeyclient.TillitisKey) bool {
	nameVer, err := tk.GetNameVersion()
	if err != nil {
		return false
	}
	// not caring about nameVer.Version
	return nameVer.Name0 == wantFWName0 &&
		nameVer.Name1 == wantFWName1
}

func isWantedApp(signer tkeypqdevicesign.Signer) bool {
	nameVer, err := signer.GetAppNameVersion()
	if err != nil {
		if !errors.Is(err, io.EOF) {
			le.Printf("GetAppNameVersion: %s\n", err)
		}
		return false
	}

	// not caring about nameVer.Version
	return nameVer.Name0 == wantAppName0 &&
		nameVer.Name1 == wantAppName1
}

// serialNumberByPath returns the USB serial number of the TKey
// currently enumerated at devPath. It only recognizes real USB serial
// ports; callers use a non-nil error as the signal that devPath is
// some other kind of serial path (for example a test harness's plain
// pty) that won't survive a USB-level reset the same way.
func serialNumberByPath(devPath string) (string, error) {
	ports, err := tkeyclient.GetSerialPorts()
	if err != nil {
		return "", fmt.Errorf("GetSerialPorts: %w", err)
	}

	for _, port := range ports {
		if port.DevPath == devPath {
			return port.SerialNumber, nil
		}
	}

	return "", fmt.Errorf("%s not found among USB serial ports", devPath)
}

// reconnectBySerialNumber waits for a TKey with the given USB serial
// number to reappear -- its device path may change across a reset --
// and connects to it, retrying transient errors such as the port
// briefly being busy right after re-enumeration. It gives up once
// timeout has elapsed since the call started.
func reconnectBySerialNumber(serialNumber string, options []func(*tkeyclient.TillitisKey), timeout time.Duration) (*tkeyclient.TillitisKey, error) {
	const retryDelay = 100 * time.Millisecond
	deadline := time.Now().Add(timeout)

	var devPath string
	for devPath == "" {
		ports, err := tkeyclient.GetSerialPorts()
		if err == nil {
			for _, port := range ports {
				if port.SerialNumber == serialNumber {
					devPath = port.DevPath
					break
				}
			}
		}
		if devPath != "" {
			break
		}
		if time.Now().After(deadline) {
			return nil, fmt.Errorf("TKey with serial number %s did not reappear", serialNumber)
		}
		time.Sleep(retryDelay)
	}

	for {
		tk := tkeyclient.New()
		err := tk.Connect(devPath, options...)
		if err == nil {
			return tk, nil
		}
		if time.Now().After(deadline) {
			return nil, fmt.Errorf("could not open %s: %w", devPath, err)
		}
		time.Sleep(retryDelay)
	}
}

func handleSignals(action func(), sig ...os.Signal) {
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, sig...)
	go func() {
		for {
			<-ch
			action()
		}
	}()
}

func readBuildInfo() string {
	var v string

	if info, ok := debug.ReadBuildInfo(); ok {
		sb := strings.Builder{}
		sb.WriteString("devel")
		for _, setting := range info.Settings {
			if strings.HasPrefix(setting.Key, "vcs") {
				sb.WriteString(fmt.Sprintf(" %s=%s", setting.Key, setting.Value))
			}
		}
		v = sb.String()
	}
	return v
}

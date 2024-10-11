"use client";

import { useState, useEffect } from "react";
import { GetServerSideProps } from 'next';
import {
    Box,
    Card,
    CardBody,
    Container,
    Heading,
    Input,
    VStack,
    Text,
    OrderedList,
    ListItem,
    useSteps,
    Breadcrumb,
    BreadcrumbItem,
    BreadcrumbLink,
    Icon,
} from "@chakra-ui/react";
import { CheckCircleIcon, TimeIcon, WarningIcon } from "@chakra-ui/icons";
import styled from "@emotion/styled";
import axios from "axios";
// import { generateJWTVerifierInputs } from "@zk-jwt/helpers/dist/input-generators";
// import { genAccountCode } from "@zk-email/relayer-utils";


declare global {
    interface Window {
        google: any;
    }
}

const StyledListItem = styled(ListItem)`
    font-family: var(--font-geist-sans);
    font-size: 1rem;
    line-height: 1.5;
    margin-bottom: 0.5rem;
    color: #4a5568;
`;

const StyledOrderedList = styled(OrderedList)`
    padding-left: 1.5rem;
    margin-bottom: 1.5rem;
`;

const InstructionStep = styled.span`
    font-weight: 600;
    color: #2b6cb0;
`;

interface HomeProps {
    data: string;
}



// Helper function to generate random BigInt
// function genAccountCode(): bigint {
//     // BN254 Scalar Field fr
//     const fr = BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617");
//     const maxBytes = 32;
//     let randomBytes = new Uint8Array(maxBytes);

//     // Continuously generate random numbers until we get one within the range [0, fr)
//     while (true) {
//         // Fill the array with random values
//         window.crypto.getRandomValues(randomBytes);

//         // Convert random bytes to a BigInt
//         let randomValue = BigInt('0x' + Array.from(randomBytes).map(byte => byte.toString(16).padStart(2, '0')).join(''));

//         // Return if the randomValue is less than max (fr in this case)
//         if (randomValue < fr) {
//             return randomValue;
//         }
//     }
// }

export default function Home() {
    const [command, setCommand] = useState("");
    const [jwt, setJwt] = useState("");
    const [error, setError] = useState("");
    const [proof, setProof] = useState(null);
    const [stepStatuses, setStepStatuses] = useState(["idle", "idle", "idle"]);

    const steps = [
        { title: "JWT Generation", description: "Generating JWT" },
        { title: "Proof Generation", description: "Starting proof generation" },
        { title: "Proof Complete", description: "Proof generation completed" },
    ];

    const { activeStep, setActiveStep } = useSteps({
        index: 0,
        count: steps.length,
    });

    const generateProof = async (jwt: string, pubkey: any) => {
        try {
            setStepStatuses((prev) => ["success", "processing", "idle"]);

            // const accountCode = await genAccountCode();
            // const circuitInputs = generateJWTVerifierInputs(
            //     jwt,
            //     pubkey,
            //     accountCode,
            //     {
            //         maxMessageLength: 1024,
            //     }
            // );
            const response1 = await axios.post('/api/generateCircuitInputs', { jwt, pubkey, maxMessageLength: 1024 });
            console.log(response1);
            const { circuitInputs, accountCode } = response1.data.circuitInputs;

            const response2 = await axios.post(
                "https://zkemail--jwt-prover-v0-1-0-flask-app.modal.run/prove/jwt",
                {
                    input: circuitInputs,
                }
            );
            console.log("Proof:", response2.data.proof);
            setProof(response2.data.proof);
            setStepStatuses((prev) => ["success", "success", "success"]);
        } catch (error) {
            console.error("Error generating proof:", error);
            setError("Failed to generate proof. Please try again.");
            setStepStatuses((prev) => ["success", "failed", "idle"]);
        }
    };

    const handleCredentialResponse = async (response: any) => {
        try {
            const jwt = response.credential;
            console.log("JWT:", jwt);
            const decodedHeader = {}
            // JSON.parse(
            //     Buffer.from(
            //         response.credential.split(".")[0],
            //         "base64"
            //     ).toString("utf-8")
            // );
            const decodedPayload = {}
            // JSON.parse(
            //     Buffer.from(
            //         response.credential.split(".")[1],
            //         "base64"
            //     ).toString("utf-8")
            // );
            console.log("Decoded Header:", decodedHeader);
            console.log("Decoded Payload:", decodedPayload);
            setJwt(jwt);
            setError("");
            setStepStatuses((prev) => ["success", "idle", "idle"]);
            const pubkeys = await axios.get(
                "https://www.googleapis.com/oauth2/v3/certs"
            );
            const pubkey = pubkeys.data.keys.find(
                (key: any) => key.kid === decodedHeader.kid
            );

            generateProof(jwt, {
                n: pubkey.n,
                e: 65537,
            });
        } catch (error) {
            console.error("Error decoding JWT:", error);
            setError(
                "Failed to process the sign-in response. Please try again."
            );
            setStepStatuses((prev) => ["failed", "idle", "idle"]);
        }
    };

    useEffect(() => {
        if (window.google) {
            window.google.accounts.id.initialize({
                client_id:
                    "397234807794-fh6mhl0jppgtt0ak5cgikhlesbe8f7si.apps.googleusercontent.com",
                callback: handleCredentialResponse,
            });
            window.google.accounts.id.renderButton(
                document.getElementById("googleSignInButton"),
                { theme: "outline", size: "large" }
            );
        }
    }, []);

    useEffect(() => {
        if (window.google) {
            window.google.accounts.id.cancel();
            if (command) {
                window.google.accounts.id.initialize({
                    client_id:
                        "397234807794-fh6mhl0jppgtt0ak5cgikhlesbe8f7si.apps.googleusercontent.com",
                    callback: handleCredentialResponse,
                    nonce: command,
                });
                window.google.accounts.id.renderButton(
                    document.getElementById("googleSignInButton"),
                    { theme: "outline", size: "large" }
                );
            }
        }
    }, [command]);

    const renderBreadcrumb = () => (
        <Breadcrumb spacing="8px" separator=">">
            {steps.map((step, index) => (
                <BreadcrumbItem key={index}>
                    <BreadcrumbLink
                        color={
                            stepStatuses[index] === "success"
                                ? "green.500"
                                : stepStatuses[index] === "processing"
                                    ? "blue.500"
                                    : stepStatuses[index] === "failed"
                                        ? "red.500"
                                        : "gray.500"
                        }
                    >
                        {stepStatuses[index] === "success" && (
                            <CheckCircleIcon mr={2} />
                        )}
                        {stepStatuses[index] === "processing" && (
                            <TimeIcon mr={2} />
                        )}
                        {stepStatuses[index] === "failed" && (
                            <WarningIcon mr={2} />
                        )}
                        {stepStatuses[index] === "idle" && (
                            <CheckCircleIcon mr={2} opacity={0.5} />
                        )}
                        {step.title}
                    </BreadcrumbLink>
                </BreadcrumbItem>
            ))}
        </Breadcrumb>
    );

    return (
        <Container maxW="container.md" centerContent>
            <Box padding={8} width="100%">
                <Heading
                    as="h1"
                    size="2xl"
                    textAlign="center"
                    mb={8}
                    color="blue.600"
                    fontFamily="var(--font-geist-sans)"
                    fontWeight="800"
                    letterSpacing="-0.05em"
                >
                    JWT-Wallet
                </Heading>
                <Card>
                    <CardBody>
                        <VStack spacing={6}>
                            <Text
                                fontSize="xl"
                                textAlign="center"
                                fontFamily="var(--font-geist-sans)"
                                fontWeight="600"
                                color="gray.700"
                            >
                                Welcome to JWT-Wallet! Follow these steps to get
                                started:
                            </Text>
                            <StyledOrderedList>
                                <StyledListItem>
                                    <InstructionStep>
                                        Enter a command
                                    </InstructionStep>{" "}
                                    in the input field below (e.g., "Send 0.12
                                    ETH to 0x1234...")
                                </StyledListItem>
                                <StyledListItem>
                                    The{" "}
                                    <InstructionStep>
                                        Google Sign-In button
                                    </InstructionStep>{" "}
                                    will become active once you've entered a
                                    command
                                </StyledListItem>
                                <StyledListItem>
                                    <InstructionStep>
                                        Click the Google Sign-In button
                                    </InstructionStep>{" "}
                                    to authenticate and generate a JWT
                                </StyledListItem>
                                <StyledListItem>
                                    <InstructionStep>
                                        Check the console
                                    </InstructionStep>{" "}
                                    for the decoded JWT information
                                </StyledListItem>
                            </StyledOrderedList>
                            <Input
                                placeholder="Enter your command here"
                                value={command}
                                onChange={(e) => setCommand(e.target.value)}
                                size="lg"
                                borderColor="blue.300"
                                _hover={{ borderColor: "blue.400" }}
                                _focus={{
                                    borderColor: "blue.500",
                                    boxShadow: "0 0 0 1px #3182ce",
                                }}
                                fontFamily="var(--font-geist-mono)"
                            />
                            <Box
                                id="googleSignInButton"
                                opacity={command ? 1 : 0.5}
                                pointerEvents={command ? "auto" : "none"}
                                transition="opacity 0.3s"
                            />
                            {renderBreadcrumb()}
                        </VStack>
                    </CardBody>
                </Card>
            </Box>
        </Container>
    );
}

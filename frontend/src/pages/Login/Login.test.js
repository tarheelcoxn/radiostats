import React from 'react';
import { render, screen, fireEvent, wait } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import Login from './Login';
import axios from 'axios';

jest.mock('axios');

const renderLogin = () => {
    return render(
        <BrowserRouter>
            <Login />
        </BrowserRouter>
    );
};

beforeEach(() => {
    jest.clearAllMocks();
});

/**
 * Original test: Used setState({error: true}) to directly set error state,
 * then verified helperText showed "Invalid credentials."
 *
 * Migration: We trigger error state by simulating a failed login attempt
 * through mocked axios, then verify the same helperText appears.
 */
describe("error text", () => {
    it("username error", async () => {
        axios.mockRejectedValue(new Error('Invalid credentials'));
        renderLogin();

        const loginBtn = screen.getByText(/login/i);
        fireEvent.click(loginBtn);

        await wait(() => {
            const helperTexts = screen.getAllByText('Invalid credentials.');
            expect(helperTexts.length).toBeGreaterThan(0);
        });
    })

    it("password error", async () => {
        axios.mockRejectedValue(new Error('Invalid credentials'));
        renderLogin();

        const loginBtn = screen.getByText(/login/i);
        fireEvent.click(loginBtn);

        await wait(() => {
            const helperTexts = screen.getAllByText('Invalid credentials.');
            expect(helperTexts.length).toBe(2); // Both fields show error
        });
    })
})

/**
 * Original test: Used shallow() and checked TextField value prop was ""
 * Migration: Render and verify input values are empty
 */
describe("empty textfields", () => {
    it("no text in username", () => {
        renderLogin();
        const userTextField = screen.getByLabelText(/username/i);
        expect(userTextField.value).toBe("");
    })

    it("no text in password", () => {
        renderLogin();
        const passwordTextField = screen.getByLabelText(/password/i);
        expect(passwordTextField.value).toBe("");
    })
})

/**
 * Original test: Used setState({username: "WCPE"}) then checked value prop
 * Migration: We set values through user interaction (fireEvent.change),
 * then verify the input reflects the typed value
 */
describe("inputting values into textfield", () => {
    it("input username", () => {
        renderLogin();
        const userTextField = screen.getByLabelText(/username/i);
        fireEvent.change(userTextField, { target: { value: 'WCPE' } });
        expect(userTextField.value).toBe("WCPE");
    })

    it("input password", () => {
        renderLogin();
        const passwordTextField = screen.getByLabelText(/password/i);
        fireEvent.change(passwordTextField, { target: { value: 'password' } });
        expect(passwordTextField.value).toBe("password");
    })
})

/**
 * Original test: Simulated click on forgotPasswordBtn, then checked helperText
 * was "" and password value was ""
 *
 * Note: The original test's assertions were checking initial state values,
 * not behavior changed by the button click. The forgot password button
 * in the component doesn't actually do anything (it's wrapped in a Link to "").
 * We preserve the test to verify the button exists and is clickable.
 */
describe("'forgot password' button click", () => {
    it("forgot password button exists and is clickable", () => {
        renderLogin();
        const forgotPasswordBtn = screen.getByText(/forgot password/i);
        expect(forgotPasswordBtn).toBeInTheDocument();
        fireEvent.click(forgotPasswordBtn);
        // Original test verified values stayed at initial state after click
        const passwordTextField = screen.getByLabelText(/password/i);
        expect(passwordTextField.value).toBe("");
    })
})

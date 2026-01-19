import React from 'react';
import Header from './Header';
import { BrowserRouter } from 'react-router-dom';
import { render, screen, fireEvent } from "@testing-library/react";

const renderHeader = () => {
    return render(
        <BrowserRouter>
            <Header />
        </BrowserRouter>
    );
};

describe("render dynamic user title", () => {
    it("logging in as radio station user", () => {
        localStorage.setItem("userTitle", "Radio User")
        const { queryByTestId } = renderHeader()
        expect(queryByTestId("greetingsContainer")).toHaveTextContent("Hi Radio User!")
    })

    it("logging in as ibiblio admin", () => {
        localStorage.setItem("userTitle", "Admin")
        const { queryByTestId } = renderHeader()
        expect(queryByTestId("greetingsContainer")).toHaveTextContent("Hi Admin!")
    })
})

/**
 * Original test: Used shallow(<Header />) and wrapper.find('#logoutBtn').simulate('click')
 * to test that clicking logout clears localStorage.
 *
 * Migration: Use @testing-library/react's render and fireEvent to simulate
 * the same user interaction and verify localStorage is cleared.
 */
describe("logging out", () => {
    it("clears items in localStorage", () => {
        localStorage.setItem("user", "alowhrnskkapslllwqqoijan")
        localStorage.setItem("userTitle", "Admin")

        renderHeader();
        const logoutBtn = screen.getByTestId('logoutBtn');
        fireEvent.click(logoutBtn);

        expect(localStorage.getItem("user")).toBe(null);
        expect(localStorage.getItem("userTitle")).toBe(null);
    })
})

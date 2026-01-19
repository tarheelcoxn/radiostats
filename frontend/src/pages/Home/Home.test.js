import React from 'react';
import { render } from '@testing-library/react';
import Home from './Home';
import { BrowserRouter } from 'react-router-dom';

describe("render without crashing", () => {
    it("renders the header", () => {
        render(<BrowserRouter><Home /></BrowserRouter>);
    })
})
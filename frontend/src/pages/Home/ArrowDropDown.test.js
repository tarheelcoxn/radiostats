import React from 'react';
import { render } from '@testing-library/react';
import ArrowDropDownBtn from './ArrowDropDownBtn';

/**
 * Original test: ReactDOM.render(<ArrowDropDownBtn/>)
 * Migration: Equivalent render using @testing-library/react
 */
describe("render without crashing", () => {
    it("renders the dropdown arrow", () => {
        render(<ArrowDropDownBtn />);
    })
})

/**
 * Original tests: Used shallow() to verify which icon component was rendered
 * based on the initSort prop.
 *
 * Original approach: wrapper.find(ArrowDropUpIcon).length / wrapper.find(ArrowDropDownIcon).length
 *
 * Migration: Material-UI icons render as SVGs with specific path data.
 * ArrowDropUpIcon: d="M7 14l5-5 5 5z"
 * ArrowDropDownIcon: d="M7 10l5 5 5-5z"
 */
describe("rendering directional arrow", () => {
    it("ascending arrow", () => {
        const { container } = render(<ArrowDropDownBtn initSort={"asc"} />);
        // When initSort is "asc", the component renders ArrowDropUpIcon
        // ArrowDropUpIcon has path d="M7 14l5-5 5 5z"
        const upArrowPath = container.querySelector('path[d="M7 14l5-5 5 5z"]');
        expect(upArrowPath).toBeInTheDocument();
    })

    it("descending arrow", () => {
        const { container } = render(<ArrowDropDownBtn initSort={"desc"} />);
        // When initSort is "desc", the component renders ArrowDropDownIcon
        // ArrowDropDownIcon has path d="M7 10l5 5 5-5z"
        const downArrowPath = container.querySelector('path[d="M7 10l5 5 5-5z"]');
        expect(downArrowPath).toBeInTheDocument();
    })
})

/**
 * Original tests: Verified that the WRONG icon was NOT present
 *
 * Migration: Same behavior - verify the opposite icon's path is not rendered
 */
describe("rendering bad directional arrow", () => {
    it("ascending arrow", () => {
        const { container } = render(<ArrowDropDownBtn initSort={"asc"} />);
        // When initSort is "asc", ArrowDropDownIcon should NOT be present
        const downArrowPath = container.querySelector('path[d="M7 10l5 5 5-5z"]');
        expect(downArrowPath).not.toBeInTheDocument();
    })

    it("descending arrow", () => {
        const { container } = render(<ArrowDropDownBtn initSort={"desc"} />);
        // When initSort is "desc", ArrowDropUpIcon should NOT be present
        const upArrowPath = container.querySelector('path[d="M7 14l5-5 5 5z"]');
        expect(upArrowPath).not.toBeInTheDocument();
    })
})
